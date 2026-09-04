Class {
	#name : 'FBBaseActivation',
	#superclass : 'Object',
	#instVars : [
		'executor',
		'node',
		'state',
		'id',
		'timestamp',
		'token'
	],
	#category : 'FluxBase-Core',
	#package : 'FluxBase-Core'
}

{ #category : 'activation' }
FBBaseActivation >> activate [
	node activateWith: self 
]

{ #category : 'events' }
FBBaseActivation >> addEvent: aFBFlowEvent [

	self flowInstance addEvent: (aFBFlowEvent
			 activation: self;
			 yourself)
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> childToken [
	^ FBToken new
		parent: self token;
		scope: self token scope;
		splitId: self token splitId;
		yourself
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> done [
	state := #done
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> waiting [
	"mark the strand I am on as parked. On my token rather than in my own field,
	because a wait outlives the step that started it - see #state and FBToken.

	Written through the ivar and not through #token: that getter answers a fresh
	throwaway token when the ivar is nil (activations persisted before it existed), so
	the mark would be dropped on exactly those. For them the old field is still the
	only place it fits, and #state reads it back from there."
	token ifNil: [ ^ state := #waiting ].
	token waiting
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> errored [ 
	state := #error
]

{ #category : 'accessing' }
FBBaseActivation >> currentValue [
	"the value of the iteration this activation is on, i.e. what #value: last wrote.

	for a plain activation that is simply #value. FBParallelActivation overrides it,
	because there #value: writes one slot of a per-iteration array while #value answers
	the whole array - so reading a written value back needs the index the write used.
	that missing counterpart is the only reason FBParallelNode>>outputFor: could not
	answer without an executor when no scope of its own is open"

	^ self value
]

{ #category : 'events' }
FBBaseActivation >> events [
	^ self flowInstance eventsOfActivation: self
]

{ #category : 'accessing' }
FBBaseActivation >> executor [

	^ executor
]

{ #category : 'accessing' }
FBBaseActivation >> executor: aFBFlowExecutor [ 
	executor := aFBFlowExecutor 
]

{ #category : 'accessing' }
FBBaseActivation >> flow [
	^ executor flow
]

{ #category : 'events' }
FBBaseActivation >> flowInstance [
	^ executor flowInstance 
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> followAll: aCollection [
	aCollection do: [ :transition |
		 self followTransition: transition ]
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> followAllOutgoing [
	(self node effectiveOutgoingFor: self) do: [ :transition |
		 self followTransition: transition ]
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> followTransition: aTransition [
	self followTransition: aTransition withToken: self childToken
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> followTransition: aTransition withToken: aToken [
	"the #requiresTrigger check belongs here, on the single choke point every
	transition passes through. FBMultiChoiceGatewayBehavior and FBAndSplitBehavior
	send this variant directly, so a check placed on #followTransition: alone (as it
	used to be, in ApptiveBase's FBBaseActivation>>followTransition:do:) was bypassed
	by exactly those two: a trigger-requiring target behind a split gateway was
	activated immediately, taking the gateway's value as its own output instead of
	waiting for the trigger. The check comes after #transitionMatches: so a branch
	condition still decides first."
	(self transitionMatches: aTransition) ifFalse: [ ^ self ].
	aTransition target requiresTrigger ifTrue: [
		^ self waitForNode: aTransition withToken: aToken ].
	executor flowInstance executor addPending: aTransition withToken: aToken
]

{ #category : 'testing' }
FBBaseActivation >> hasError [
	^ state = #error
]

{ #category : 'accessing' }
FBBaseActivation >> id [

	^ id
]

{ #category : 'initialization' }
FBBaseActivation >> initialize [
	super initialize.
	id := FBIdGenerator current newId.
	timestamp := DateAndTime now.
	state := #created.
	token := FBToken new activation: self; yourself
]

{ #category : 'accessing' }
FBBaseActivation >> instance [
	^ executor flowInstance
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> isDone [
	^ state = #done
]

{ #category : 'accessing' }
FBBaseActivation >> node [
	^ node
]

{ #category : 'accessing' }
FBBaseActivation >> node: aFBNode [
	node := aFBNode
]

{ #category : 'services' }
FBBaseActivation >> output [

	^ self node outputFor: self
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> shouldFollowTransition: aTransition with: value [
	^ (aTransition conditionMatches: value)
]

{ #category : 'accessing' }
FBBaseActivation >> state [
	"#created, #done and #error are statements about me - a step - and live in my own
	field. #waiting is not: a wait outlives the step that started it, so it lives on my
	token (see FBToken) and is read back from there.

	Deliberately not a plain delegation to #token state. #token answers a fresh
	throwaway token for activations persisted before that ivar existed, and a fresh
	token is #ready - every one of those finished activations would report itself
	ready. The ivar is the fallback for them, and #waiting is the only value it no
	longer receives."
	token ifNotNil: [ token isWaiting ifTrue: [ ^ #waiting ] ].
	^ state
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> token [
	"Content-sicherer Getter: bereits persistierte, alte Activations aus der Zeit vor der token-Ivar haben token = nil.
	Fuer diese wird bei jedem Lesen ein frischer Default zurueckgegeben, OHNE ihn in die Ivar zurueckzuschreiben -
	sonst wuerde ein reiner Lesezugriff die Activation als geaendert markieren (Modification on Read, siehe FBFlowInstance>>metadata)."
	^ token ifNil: [ FBToken new activation: self; yourself ]
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> token: aFBToken [
	token := aFBToken.
	aFBToken ifNotNil: [ aFBToken activation: self ]
]

{ #category : 'accessing' }
FBBaseActivation >> sourceNode [
	"The node I arrived from, i.e. which of my node's incoming transitions was actually
	taken to produce me. Not derivable from the graph - my node may have several
	incoming transitions, and a loop passes the same one repeatedly - so it comes from
	my token's parent, which is the token of the activation that spawned me."
	^ self token parent
		ifNotNil: [ :parentToken | parentToken node ]
		ifNil: [ self legacySourceNode ]
]

{ #category : 'accessing' }
FBBaseActivation >> legacySourceNode [
	"Tokens persisted before FBToken held a real #parent reference only carry the
	parent's id, so resolve it the way FBJoinBehavior used to: search this instance's
	activations for the one owning that token. Remove together with FBToken>>parentId
	once no such tokens are left in any store."
	| parentTokenId |
	parentTokenId := self token parentId ifNil: [ ^ nil ].
	^ (self instance activations
		detect: [ :each | each token id = parentTokenId ]
		ifNone: [ nil ]) ifNotNil: [ :each | each node ]
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> transitionMatches: aTransition [
	"Hook subclasses can override to establish whatever evaluation context a
	transition's condition needs (e.g. AGFlowActivation wraps this in the
	transition's own ApptiveScript scope so conditions like 'source.input'
	can resolve). The plain FluxBase-Core default has no such context."
	^ aTransition conditionMatches: self value
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> waitForNode: aNode [
	self waitForNode: aNode withToken: nil
]

{ #category : 'as yet unclassified' }
FBBaseActivation >> waitForNode: aNode withToken: aToken [
	"aToken is the token the target would have been activated with. It has to be kept
	across the suspension: whoever resumes builds a fresh activation, and without the
	token that activation loses its #splitId - a form suspended behind a split gateway
	would then reach a downstream join under a different split id and the join could
	never complete."
	self waiting.
	executor addWaiting: aNode withToken: aToken
]
