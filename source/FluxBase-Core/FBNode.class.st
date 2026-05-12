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

	^ true
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

{ #category : 'converting' }
FBNode >> asRoassalShape [
	^ RSLabel new text: 'N/A'
]

{ #category : 'accessing' }
FBNode >> behaviorClass [

	^ behaviorClass 
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

{ #category : 'accessing' }
FBNode >> defaultBehaviorClass [
	self subclassResponsibility 
]

{ #category : 'as yet unclassified' }
FBNode >> detach [
	incoming copy do: #detach.
	outgoing copy do: #detach.
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
	outgoing := OrderedCollection new.
	behaviorClass := self defaultBehaviorClass 
]

{ #category : 'as yet unclassified' }
FBNode >> inspectionFlow: aBuilder [
	<inspectorPresentationOrder: 0 title: 'flow'>
	^ aBuilder newRoassal 
		canvas: (FBFlowMapBuilder new 
			nodes: self neighbourNodes;
			build )
		yourself
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

{ #category : 'initialization' }
FBNode >> setFlow: aFlow [ 
	flow := aFlow
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
