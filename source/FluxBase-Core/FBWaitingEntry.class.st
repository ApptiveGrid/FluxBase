"
I am one waiting spot of a flow instance, reified so that it can be addressed from
outside the image.

	correlationId	my address, inherited from FBWaitingAddress. Minted per suspension
			and unique across instances, so that the routing part of an outward
			address never becomes the authoritative part. ApptiveGrid builds the
			address a caller sees - a form link, a remote callback uri - out of
			me; I do not build it.
	token		the strand that is parked here. Whoever resumes through me by
			minting a fresh activation has to hand this token to it, or that
			activation loses its splitId and a join behind it can never
			complete - see FBBaseActivation>>waitForNode:withToken:.
	suspension	the very object that was put into FBBaseExecutor>>suspended: the
			transition, where a transition into a trigger-requiring node was
			suspended, and the node itself, where a condition wait parked. It
			is what a resume has to take back out of #suspended, and what the
			waiting node is read off of to build a form link.

Why #suspension is stored rather than derived from #token: #suspended takes
duplicates and the same object really is suspended repeatedly - a parallel scope
suspends the same transition once per iteration. Node identity is therefore too
coarse to name a waiting spot, which is the whole reason a correlationId exists.
Deriving would put that ambiguity right back in.

I deliberately carry no deadline. The schedule that may time this wait out is
authoritative for it and I hold no copy, so there is no duplicate to keep in step
across the two stores - and a schedule that fires and finds nobody waiting is
allowed to lapse silently.

I am created by FBBaseActivation>>waitForNode:withToken: when the waiting node asks to
be reachable, which is also where #token comes from - that is the one place that knows
the strand being parked. Unless a reservation already stands for that wait: then the
reservation is its address and no second one is minted - see FBWaitingReservation, my
sibling under FBWaitingAddress for an address handed out ahead of its wait.
"
Class {
	#name : 'FBWaitingEntry',
	#superclass : 'FBWaitingAddress',
	#instVars : [
		'token',
		'suspension'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'printing' }
FBWaitingEntry >> printOn: aStream [
	aStream << 'waiting entry correlationId=' << correlationId asString
]

{ #category : 'testing' }
FBWaitingEntry >> matchesSuspension: anObject [
	"by identity - see FBWaitingAddress>>matchesSuspension:"
	^ suspension == anObject
]

{ #category : 'resuming' }
FBWaitingEntry >> resumeIn: anInstance with: aValue [
	"hand aValue to the wait I name and answer the activation that went on, or nil when
	the wait was gone.

	I take myself out of the registry first, whether or not my suspension turns out to
	still be open: an entry whose suspension is gone - a node-addressed resume took it in
	the meantime - names a wait that is over, and is spent either way. That is what a
	second delivery of the same impulse rests on. A reservation decides this differently,
	see FBWaitingReservation>>resumeIn:with:.

	My own token is what is taken off the executor's queue and what the wait goes on
	with, by identity - see FBBaseExecutor>>resume:withToken:value:"

	| holder |
	anInstance takeWaitingEntryFor: correlationId.
	holder := anInstance activeExecutors
		detect: [ :each | each suspended includes: suspension ]
		ifNone: [ ^ nil ].
	^ holder resume: suspension withToken: token value: aValue
]

{ #category : 'accessing' }
FBWaitingEntry >> suspension [
	"the object that was put into FBBaseExecutor>>suspended for this wait - a
	transition or a node, see my class comment"
	^ suspension
]

{ #category : 'accessing' }
FBWaitingEntry >> suspension: anObject [
	suspension := anObject
]

{ #category : 'accessing' }
FBWaitingEntry >> waitingNode [
	"the node that waits at my spot - read off the suspension, which is a transition in one
	case and a node in the other (FBTransition>>waitingNode / FBNode>>waitingNode). This
	is what ApptiveGrid reads to build a form link, so ask me rather than my suspension: a
	reservation has no suspension yet and answers its target instead"
	^ suspension waitingNode
]

{ #category : 'accessing' }
FBWaitingEntry >> token [
	"the strand parked here, to be carried across the suspension - see my class comment"
	^ token
]

{ #category : 'accessing' }
FBWaitingEntry >> token: aFBToken [
	token := aFBToken
]

{ #category : 'testing' }
FBWaitingEntry >> liesInScope: aScope [
	"my token is the parked strand's own"
	^ token notNil and: [ aScope encloses: token scope ]
]

{ #category : 'testing' }
FBWaitingEntry >> tokenSatisfies: aBlock [
	^ token notNil and: [ aBlock value: token ]
]
