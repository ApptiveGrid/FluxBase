"
I am one waiting spot of a flow instance, reified so that it can be addressed from
outside the image.

	correlationId	my address. Minted per suspension and unique across instances,
			so that the routing part of an outward address never becomes the
			authoritative part. ApptiveGrid builds the address a caller sees -
			a form link, a remote callback uri - out of me; I do not build it.
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

Nothing in the engine creates me yet.
"
Class {
	#name : 'FBWaitingEntry',
	#superclass : 'Object',
	#instVars : [
		'correlationId',
		'token',
		'suspension'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBWaitingEntry >> correlationId [
	"my address from outside - see my class comment"
	^ correlationId
]

{ #category : 'accessing' }
FBWaitingEntry >> correlationId: aString [
	correlationId := aString
]

{ #category : 'printing' }
FBWaitingEntry >> printOn: aStream [
	aStream << 'waiting entry correlationId=' << correlationId asString
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
FBWaitingEntry >> token [
	"the strand parked here, to be carried across the suspension - see my class comment"
	^ token
]

{ #category : 'accessing' }
FBWaitingEntry >> token: aFBToken [
	token := aFBToken
]
