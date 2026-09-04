"
I am the directory of the waiting spots of one FBFlowInstance that are meant to be
reachable from outside, keyed by correlationId.

I am not the instance's wait bookkeeping. That is FBBaseExecutor>>suspended - one
collection per executor frame, and what decides whether a frame can still advance. I
am a selection out of it: every entry of mine points at one suspension there, but a
suspension whose waker is not outside - a condition wait on a date - has no entry
here. Being in me is a release, not a technical detail.

What I add is not the lookup but the individuation. #suspended takes duplicates and
its elements have no identity as waiting spots: a parallel scope suspends the same
transition once per iteration, which is why FBBaseExecutor>>suspendedTokens had to
become a queue per key, and why node identity is too coarse to serve as an address.
Each of my entries gives one single suspension an identity of its own.

Two things follow from being a class rather than a Dictionary. #takeEntryFor: is the
idempotency point: it answers the entry and forgets it, and answers nil both for an
id that was never registered and for one already consumed. Absence is the answer to a
second submit, not an error. And entries are only created through
FBFlowInstance>>registerWaitingToken:suspendedAt:, so being reachable from outside
stays something a caller asks for.

I hang on the flow instance and not on the executor because an executor is a stack
frame - pushed and popped, and FBFlowInstance>>executors is derived precisely so that
finished frames cannot linger in a second structure - while a form link has to stay
resolvable for weeks. Same choice as FBFlowInstance>>activations and #joinStates,
which FBBaseExecutor's comment calls out as deliberately not executor-local state.

A wait inside a local sub flow is registered on the child instance, where its
suspension is: the child holds no reference back to its caller. Resolving from
outside therefore walks the chain of active instances - FBFlowInstance>>waitingEntryFor:
does that - which is the same two-level split #suspended already has, one level up.

Nothing in the engine creates entries yet. I am additive, the way FBJoinState was
before the joins were wired to it.
"
Class {
	#name : 'FBWaitingRegistry',
	#superclass : 'Object',
	#instVars : [
		'entriesByCorrelationId'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBWaitingRegistry >> entries [
	"my open entries, in the order they were registered"
	^ entriesByCorrelationId values
]

{ #category : 'accessing' }
FBWaitingRegistry >> entryFor: aCorrelationId [
	"the entry under aCorrelationId, or nil. A pure read - it consumes nothing"
	^ entriesByCorrelationId at: aCorrelationId ifAbsent: [ nil ]
]

{ #category : 'initialization' }
FBWaitingRegistry >> initialize [
	super initialize.
	entriesByCorrelationId := OrderedDictionary new
]

{ #category : 'printing' }
FBWaitingRegistry >> printOn: aStream [
	aStream << 'waiting registry entries=' << entriesByCorrelationId size asString
]

{ #category : 'accessing' }
FBWaitingRegistry >> registerToken: aToken suspendedAt: anObject [
	"mint an address for one suspension and answer the entry filed under it. The id is
	minted in this one place so that it is unique across instances rather than only
	within one - see my class comment"
	| entry |
	entry := FBWaitingEntry new
		correlationId: FBIdGenerator current newId;
		token: aToken;
		suspension: anObject;
		yourself.
	entriesByCorrelationId at: entry correlationId put: entry.
	^ entry
]

{ #category : 'accessing' }
FBWaitingRegistry >> takeEntryFor: aCorrelationId [
	"answer the entry under aCorrelationId and forget it, or nil when there is none.
	An unknown id and an already consumed one give the same answer, which is what makes
	resuming through me idempotent - see my class comment"
	^ entriesByCorrelationId removeKey: aCorrelationId ifAbsent: [ nil ]
]
