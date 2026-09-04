Class {
	#name : 'FBNode',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'flow',
		'incoming',
		'outgoing',
		'behaviorClass',
		'properties'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBNode class >> isAbstract [

	^ self == FBNode
]

{ #category : 'instance creation' }
FBNode class >> named: aString [ 
	^ self new 
		name: aString
]

{ #category : 'associating' }
FBNode >> --> aNode [ 
	^ aNode addTo: self.

]

{ #category : 'instance creation' }
FBNode >> activateWith: anFBActivation [
	anFBActivation node: self. 
	^ self behaviorClass new
		activation: anFBActivation;
		execute	
]

{ #category : 'connecting' }
FBNode >> addIncoming: aFBTransition [ 
	(incoming includes: aFBTransition) ifTrue: [ ^ self ]. 

	self checkForCycle.
	incoming add: aFBTransition.
	"nodes can be connected in multiple ways not necessarily early connected
	to the start node. So we try to propagate the flow whenever there is a 
	new transition"
	(flow isNil and: [ aFBTransition source flow notNil ])
		ifTrue: [ 
			self flow: aFBTransition source flow ].

]

{ #category : 'connecting' }
FBNode >> addIncomingNode: aFBNode [ 
	self addIncoming: (self transitionClass source: aFBNode target: self).
	^ aFBNode 
]

{ #category : 'connecting' }
FBNode >> addOutgoing: aFBTransition [ 
	(outgoing includes: aFBTransition) ifTrue: [ ^ self ]. 
	
	self checkForCycle
	outgoing add: aFBTransition.
	aFBTransition target addIncoming: aFBTransition.
	"nodes can be connected in multiple ways not necessarily early connected
	to the start node. So we try to propagate the flow whenever there is a 
	new transition"

	(flow isNil and: [ aFBTransition target flow notNil ])
		ifTrue: [ 
			self flow: aFBTransition target flow ].

]

{ #category : 'connecting' }
FBNode >> addOutgoingNode: aFBNode [ 
	self addOutgoing: (self transitionClass source: self target: aFBNode).
	^ aFBNode 
]

{ #category : 'adding' }
FBNode >> addTo: aFBNode [
	aFBNode addOutgoingNode: self.
	^ self
]

{ #category : 'accessing' }
FBNode >> behaviorClass [

	^ behaviorClass ifNil: [ self defaultBehaviorClass ]
]

{ #category : 'accessing' }
FBNode >> behaviorClass: anObject [

	behaviorClass := anObject
]

{ #category : 'connecting' }
FBNode >> checkForCycle [ 
	| nodes |
	flow 
		ifNotNil: [self checkForCycle: flow nodes ]
		ifNil: [ 
			nodes := Set new.
			self collectionNeighborsIn: nodes.
			self checkForCycle: nodes  ].

	
]

{ #category : 'connecting' }
FBNode >> checkForCycle: aCollection [
	(FBTopologicalSorter new 
		nodes: aCollection; 
		hasCycle) 
			ifTrue: [ FBFlowIsCyclic signal: 'flow contains a cycle' ]
]

{ #category : 'as yet unclassified' }
FBNode >> collectionNeighborsIn: aCollection [ 
	(aCollection includes: self) ifTrue: [ ^ self ].
	aCollection add: self.
	incoming do: [:each | each source collectionNeighborsIn: aCollection ].
	outgoing do: [:each | each target collectionNeighborsIn: aCollection ].

]

{ #category : 'converting' }
FBNode >> convertTo: aClass [
	"Answer a new instance of aClass carrying over this node's identity and
	connections: id, name, properties, behaviorClass override (only if it was
	actually set on the receiver), flow, and incoming/outgoing transitions
	(repointed to the new node). The receiver ends up fully detached from the
	flow graph -- it is not itself removed from anywhere, it simply becomes
	unreferenced once nothing else points at it.

	Used to migrate a persisted node to a different, structurally compatible
	node class -- see FBFlow>>convertNode:toClass:."
	| newNode |
	newNode := aClass new.
	newNode setId: id.
	newNode name: name.
	newNode properties: properties.
	behaviorClass ifNotNil: [ newNode behaviorClass: behaviorClass ].
	newNode setFlow: flow.
	newNode setIncoming: incoming copy.
	newNode setOutgoing: outgoing copy.
	incoming do: [ :each | each target: newNode ].
	outgoing do: [ :each | each source: newNode ].
	^ newNode
]

{ #category : 'accessing' }
FBNode >> defaultBehaviorClass [
	self subclassResponsibility
]

{ #category : 'as yet unclassified' }
FBNode >> detach [
	incoming copy do: #detach.
	outgoing copy do: #detach.
]

{ #category : 'execution' }
FBNode >> effectiveOutgoingFor: anActivation [
	"the transitions to actually follow once this node's activation is done:
	its own #outgoing if it has any, otherwise (unless this node is itself
	already a flow terminal) a synthesized, ad-hoc transition to an implicit
	join/end node - never persisted, never wired into any real node's own
	#outgoing/#incoming, and never added to the flow definition - resolved
	through the current executor so a node reached from inside a parallel
	scope implicitly joins that scope, and a node reached at the outermost
	level implicitly reaches the flow's end. see FBBaseExecutor>>impliedTransitionFrom:"

	outgoing isEmpty ifFalse: [ ^ outgoing ].
	self isFlowTerminal ifTrue: [ ^ #() ].
	^ Array with: (anActivation instance executor impliedTransitionFrom: self)
]

{ #category : 'as yet unclassified' }
FBNode >> findEnd [
	(self isKindOf: FBEndEvent) ifTrue: [ ^ self ]. 
	outgoing do: [ :transition |
		(transition target findEnd ifNotNil: [:end | ^ end ]) ].
	^ nil
]

{ #category : 'accessing' }
FBNode >> flow [
	^ flow 
]

{ #category : 'initialization' }
FBNode >> flow: aFBFlow [ 
	flow ifNil: [.
		aFBFlow addNode: self ].
	self propagateFlow 

]

{ #category : 'testing' }
FBNode >> hasOutgoing [ 
	^ outgoing notEmpty
]

{ #category : 'accessing' }
FBNode >> id [
	^ id
]

{ #category : 'accessing' }
FBNode >> incoming [

	^ incoming
]

{ #category : 'accessing' }
FBNode >> incomingNodes [

	^ incoming collect: #source
]

{ #category : 'initialization' }
FBNode >> initialize [ 
	super initialize.
	id := FBIdGenerator current newId.
	incoming := OrderedCollection new.
	outgoing := OrderedCollection new
]

{ #category : 'testing' }
FBNode >> isFlowTerminal [
	"true for a node that already represents 'nothing more happens after
	this' (e.g. FBEndEvent) - #effectiveOutgoingFor: must not synthesize an
	implicit continuation past one of these"

	^ false
]

{ #category : 'accessing' }
FBNode >> lastValueIn: aFBFlowExecutor [
	^ aFBFlowExecutor lastValueOf: self
]

{ #category : 'accessing' }
FBNode >> metadataSchema [
	^ self behaviorClass metadataSchema
]

{ #category : 'accessing' }
FBNode >> name [
	^ name
]

{ #category : 'accessing' }
FBNode >> name: aString [ 
	name := aString
]

{ #category : 'as yet unclassified' }
FBNode >> neighbourNodes [
	^ ((incoming collect: #source), (outgoing collect: #target)) add: self; yourself
]

{ #category : 'accessing' }
FBNode >> outgoing [
	^ outgoing
]

{ #category : 'accessing' }
FBNode >> outgoingNodes [

	^ outgoing collect: #target
]

{ #category : 'services' }
FBNode >> outputFor: anActivation [
	"hook so that the output of an activation can be specifically computed according to the kind of node being processed.
	default behavior is to propagate the activation value"
	
	^ anActivation value
]

{ #category : 'testing' }
FBNode >> requiresTrigger [
	"hook: does this node only proceed on an explicit external trigger (e.g. a
	submitted form)? such a node must not be activated when a transition into it is
	followed - the transition is suspended instead, see
	FBBaseActivation>>followTransition:withToken:"

	^ false
]

{ #category : 'testing' }
FBNode >> isExternallyResumable [
	"hook: should a wait at this node be made reachable from outside, that is, get an
	entry in the flow instance's FBWaitingRegistry? A form node and a remote sub flow
	node have a waker outside the image and answer true; a condition wait on a date has
	none and does not. Being reachable is a release, so it is asked of each node rather
	than granted to everything that waits.

	Sits next to #requiresTrigger, the other question asked of a node around a
	transition into it. Nothing consults this yet"

	^ false
]

{ #category : 'printing' }
FBNode >> printOn: aStream [ 
	aStream << 'node name=' << name asString
]

{ #category : 'as yet unclassified' }
FBNode >> propagateFlow [
	"try setting the flow in the neighbor nodes. This can bubble
	up and down to be sure every node has a flow set"
	incoming do: [ :each |
		each source flow isNil ifTrue: [
			each source flow: flow.
			each source propagateFlow ] ].
	outgoing do: [ :each |
		each target flow isNil ifTrue: [
			each target flow: flow.
			each target propagateFlow ] ]
]

{ #category : 'accessing' }
FBNode >> properties [
	^ properties
]

{ #category : 'as yet unclassified' }
FBNode >> properties: anObject [

	properties := anObject
]

{ #category : 'properties' }
FBNode >> propertiesDo: aBlock [ 
	properties ifNil: [ ^ self ].
	^ properties keysAndValuesDo: aBlock 
]

{ #category : 'properties' }
FBNode >> propertyAt: aString [ 
	properties ifNil: [ ^ nil ].
	^ self properties at: aString ifAbsent: [ nil ]
]

{ #category : 'as yet unclassified' }
FBNode >> propertyAt: aString ifAbsent: aBlock [
	properties ifNil: [ ^ aBlock value ].
	^ properties at: aString ifAbsent: aBlock
]

{ #category : 'properties' }
FBNode >> propertyAt: key put: aValue [ 
	properties ifNil: [ properties := FBProperties new ].
	properties 
		at: key 
		put: aValue
]

{ #category : 'as yet unclassified' }
FBNode >> propertySchema [
	^ self behaviorClass propertySchema
]

{ #category : 'accessing' }
FBNode >> propertySchemaAt: aString [ 
	^ self propertySchema at: aString
]

{ #category : 'accessing' }
FBNode >> propertySchemaAt: aString put: aType [
	^ self propertySchema 
		at: aString
		put: aType
]

{ #category : 'removing' }
FBNode >> remove [ 
	self detach.
	flow basicRemoveNode: self.
]

{ #category : 'removing' }
FBNode >> removeIncoming: aFBTransition [ 
	incoming remove: aFBTransition 
]

{ #category : 'removing' }
FBNode >> removeOutgoing: aFBTransition [ 
	outgoing remove: aFBTransition 
]

{ #category : 'as yet unclassified' }
FBNode >> resultTransition: aSymbol [
    "convenience analogous to #when: -- builds an unattached transition to self,
    tagged with resultName, for wiring result-specific outgoing branches
    (e.g. from a FBSubFlowNode). use as: aNode --> (target resultTransition: #error)"
    ^ self transitionClass new
        target: self;
        resultName: aSymbol;
        yourself
]

{ #category : 'initialization' }
FBNode >> setFlow: aFlow [
	flow := aFlow
]

{ #category : 'initialization' }
FBNode >> setId: anId [
	"Low-level identity setter, used only by #convertTo: when migrating a
	persisted node to a different node class while preserving its id."
	id := anId
]

{ #category : 'initialization' }
FBNode >> setIncoming: aCollection [
	"Low-level setter, used only by #convertTo:."
	incoming := aCollection
]

{ #category : 'initialization' }
FBNode >> setOutgoing: aCollection [
	"Low-level setter, used only by #convertTo:."
	outgoing := aCollection
]

{ #category : 'connecting' }
FBNode >> transitionClass [
	^ FBFlow transitionClass
]

{ #category : 'accessing' }
FBNode >> value [ 
	^ nil
]

{ #category : 'as yet unclassified' }
FBNode >> when: aBlock [ 
	^ self transitionClass new 
		target: self;
		condition: aBlock
]
