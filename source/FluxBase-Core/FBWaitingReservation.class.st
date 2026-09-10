"
I am an address for a waiting spot that does not exist yet: handed out ahead of the wait,
so that it can go into a mail before the flow reaches the node that will park.

	targetNode	the node the wait will be at
	anchorToken	the token of the activation that reserved me. The wait I stand for is
			the one whose token descends from it (FBToken>>hasAncestor:). That is
			what tells two iterations of a parallel scope apart: a link node inside
			the scope runs once per iteration and reserves once per iteration, and
			each reservation resolves to the wait on its own strand. Node identity
			cannot do this - the same node parks once per iteration.

I resolve when I am signalled, not when the wait parks. Redeeming at parking time would
shut the door on sub flows for good: a reservation handed out in an outer instance for a
form inside a local sub flow is invisible to the child, which holds no reference back to
its caller. Resolving through FBFlowInstance>>activeExecutors walks the chain instead.
A sub flow is reached because FBFlowInstance>>descendFrom: links the child's first token
to the caller's, so a wait inside it descends from my anchor like any other. What parking
does is skip minting a second address when I already stand for the wait
(FBBaseActivation>>waitForNode:withToken:, through #reservesWaitAt:forToken:, looked for
along the strand), so there is one address per wait, however deep it parks.

Unlike a plain entry I am NOT spent when I cannot be resolved: a signal that arrives before
the flow has reached my node - a click on the mail link too early - answers false and
leaves me standing, because the wait I am the address of may still come. I am spent only
when I actually resumed something. What I do not cover is a flow that never reaches my
node at all; that reservation stays until something outside takes it away.

A sibling of FBWaitingEntry under FBWaitingAddress, not a subclass of it: I hold neither
a token nor a suspension, and an entry holds neither a target nor an anchor. What we
share is the correlationId and the protocol signal:with: speaks, and that is what the
superclass carries.
"
Class {
	#name : 'FBWaitingReservation',
	#superclass : 'FBWaitingAddress',
	#instVars : [
		'targetNode',
		'anchorToken'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBWaitingReservation >> anchorToken [
	"the token of the activation that reserved me - the wait I stand for descends from it"
	^ anchorToken
]

{ #category : 'accessing' }
FBWaitingReservation >> anchorToken: aFBToken [
	anchorToken := aFBToken
]

{ #category : 'printing' }
FBWaitingReservation >> printOn: aStream [
	aStream << 'waiting reservation correlationId=' << correlationId asString
		<< ' at ' << targetNode printString
]

{ #category : 'testing' }
FBWaitingReservation >> reservesWaitAt: aNode forToken: aToken [
	"do I stand for a wait at aNode on aToken's strand? Asked when such a wait parks, so
	that it does not mint a second address next to me"
	^ targetNode == aNode and: [ aToken notNil and: [ aToken hasAncestor: anchorToken ] ]
]

{ #category : 'resuming' }
FBWaitingReservation >> resumeIn: anInstance with: aValue [
	"find the wait I stand for - at my target node, on a strand descending from my
	anchor - and hand it aValue. Answers the activation that went on, or nil when no
	such wait has parked yet.

	Searched over the chain of active executors, so that a wait in a sub flow of the
	instance that handed me out is found too. The token is what individuates: #suspended may hold
	the same transition once per parallel iteration, so the matching token is taken off
	the queue first and the resume is then made with exactly that one.

	I am taken out of the registry only once a wait was found. Before that I am not spent:
	a signal that arrives before the flow has parked at my node answers false and leaves
	me standing for the wait that may still come.

	A wait that parked without seeing me has registered an address of its own; that entry
	names a suspension that is over once I resumed it, and the resume drops it - see
	FBBaseExecutor>>resume:withToken:value:, which clears that for every continuation"

	anInstance activeExecutors do: [ :executor |
		(executor suspended detect: [ :each | each waitingNode == targetNode ] ifNone: [ nil ])
			ifNotNil: [ :found |
				(executor
					takeTokenForSuspended: found
					satisfying: [ :each | each hasAncestor: anchorToken ])
						ifNotNil: [ :token |
							anInstance takeWaitingEntryFor: correlationId.
							"the token is already off the queue, so the take inside #resume:
							withToken:value: finds nothing and consumes no other"
							^ executor resume: found withToken: token value: aValue ] ] ].
	^ nil
]

{ #category : 'accessing' }
FBWaitingReservation >> targetNode [
	"the node the wait I stand for will be at"
	^ targetNode
]

{ #category : 'accessing' }
FBWaitingReservation >> targetNode: aFBNode [
	targetNode := aFBNode
]

{ #category : 'accessing' }
FBWaitingReservation >> waitingNode [
	"no suspension yet - the node the wait will be at is what a link is built from"
	^ targetNode
]

{ #category : 'testing' }
FBWaitingReservation >> liesInScope: aScope [
	"my anchor is the token of the activation that handed me out - the wait I stand for
	descends from it, so it lives where the anchor lives"
	^ anchorToken notNil and: [ aScope encloses: anchorToken scope ]
]

{ #category : 'testing' }
FBWaitingReservation >> tokenSatisfies: aBlock [
	^ anchorToken notNil and: [ aBlock value: anchorToken ]
]
