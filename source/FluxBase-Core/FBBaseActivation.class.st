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
FBBaseActivation >> resumed [
	"the wait #waiting marked is over. The mark lives on my token (see #waiting), so it is
	taken back there. An activation persisted before tokens existed keeps the mark in
	its own field: for it the step had finished when it parked (FBTaskBehavior>>execute
	marks #done before it follows), so #done is what the field goes back to"
	token ifNil: [
		state = #waiting ifTrue: [ state := #done ].
		^ self ].
	token resumed
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
FBBaseActivation >> waitForNode: aSuspension withToken: aToken [
	"park aSuspension - a transition into a trigger-requiring node, or a node that stopped
	inside its own execution - and make the wait reachable from outside if its node asks
	for it.

	aToken is the token the waiting node would have been activated with. It has to be kept
	across the suspension: whoever resumes builds a fresh activation, and without the
	token that activation loses its #splitId - a form suspended behind a split gateway
	would then reach a downstream join under a different split id and the join could
	never complete.

	The one place a suspension is created, which is why the registration sits here: the
	token is at hand, and #flowInstance is the instance whose executor holds the
	suspension - for a wait inside a sub flow that is the child, which is where
	FBWaitingRegistry wants the entry. Being reachable is asked of the node
	(FBNode>>isExternallyResumable, false by default) rather than granted to everything
	that waits, so a condition wait on a date still gets no entry.

	Answers the address the wait is reachable under - the entry just registered, or the
	reservation that already stood for it - and nil for a wait nothing outside can reach.
	A node that has to tell the outside where to come back to, FBRemoteFlowTask, reads
	its correlationId off this answer; nobody else needs it.

	There used to be a one-argument #waitForNode: passing nil for the token. It lost its
	last caller when the condition wait started handing over its own token, and is gone:
	a path that parks without a token is a path that produces an entry with no #splitId."
	self waiting.
	executor addWaiting: aSuspension withToken: aToken.
	aSuspension waitingNode isExternallyResumable ifFalse: [ ^ nil ].
	"an address handed out ahead of this wait - a link that went into a mail before the
	flow got here - is its address; minting a second one would leave two for one wait.
	Looked for along the strand, not only in my own instance: the link may have been
	built in the instance that called this sub flow, and the child's first token descends
	from the caller's (FBFlowInstance>>descendFrom:)"
	aToken ifNotNil: [
		aToken instancesAlongAncestry do: [ :each |
			(each reservationAt: aSuspension waitingNode forToken: aToken)
				ifNotNil: [ :reservation | ^ reservation ] ] ].
	^ self flowInstance registerWaitingToken: aToken suspendedAt: aSuspension
]
