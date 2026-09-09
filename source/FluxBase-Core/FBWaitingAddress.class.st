"
I am an address under which a waiting spot of a flow instance can be reached from
outside the image. My correlationId is that address; what I point at differs between my
two kinds, and that difference is the whole reason I exist as a superclass:

	FBWaitingEntry		names a wait that is parked - it holds the suspension and the
				token, and is spent as soon as it is signalled
	FBWaitingReservation	names a wait that has not parked yet - it holds the node the
				wait will be at and the token it will descend from, and is
				spent only once it really resumed something

FBFlowInstance>>signal:with: does not tell the two apart. It looks the address up and
sends #resumeIn:with:; the address resolves itself and decides when it is spent. The
same move FBBaseExecutor>>resume:withToken:value: makes with the suspension: the entrance
stays plain, the variety sits with what was addressed.

Both kinds live in FBWaitingRegistry under their correlationId, minted in one place so
that it is unique across instances. Whoever builds an outward form of me - a form link,
a callback uri - reads #waitingNode, which both kinds answer.
"
Class {
	#name : 'FBWaitingAddress',
	#superclass : 'Object',
	#instVars : [
		'correlationId'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBWaitingAddress >> correlationId [
	"my address from outside - see my class comment"
	^ correlationId
]

{ #category : 'accessing' }
FBWaitingAddress >> correlationId: aString [
	correlationId := aString
]

{ #category : 'testing' }
FBWaitingAddress >> matchesSuspension: anObject [
	"do I stand for the wait whose suspension is anObject - the very object in
	FBBaseExecutor>>suspended? Asked by whoever consumed that suspension on a path of its
	own and now drops the addresses that pointed at it (ApptiveBase's resume paths, and a
	reservation that resolved next to an entry a sub flow child registered). A reservation
	holds no suspension and answers false; ask this rather than #suspension, which only an
	entry understands"
	^ false
]

{ #category : 'testing' }
FBWaitingAddress >> reservesWaitAt: aNode forToken: aToken [
	"am I an address handed out ahead of a wait at aNode on aToken's strand? Asked when
	such a wait parks, so that it does not mint a second address next to me. Only a
	reservation is - see FBWaitingReservation"
	^ false
]

{ #category : 'resuming' }
FBWaitingAddress >> resumeIn: anInstance with: aValue [
	"hand aValue to the wait I stand for, take myself out of anInstance's registry when
	that is the right moment for my kind, and answer whether anything was resumed"
	^ self subclassResponsibility
]

{ #category : 'accessing' }
FBWaitingAddress >> waitingNode [
	"the node that waits, or will wait, at my spot - what an outward form of me is built
	from"
	^ self subclassResponsibility
]
