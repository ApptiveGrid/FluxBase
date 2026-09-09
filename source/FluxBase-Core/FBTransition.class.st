Class {
	#name : 'FBTransition',
	#superclass : 'Object',
	#instVars : [
		'id',
		'source',
		'target',
		'condition',
		'resultName'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBTransition class >> source: aSourceNode target: aTargetNode [ 
	^ self new 
		source: aSourceNode;
		target: aTargetNode
]

{ #category : 'associating' }
FBTransition >> --> aNode [ 
	^ target --> aNode
]

{ #category : 'visiting' }
FBTransition >> acceptFluxBase: aVisitor [
	^ aVisitor visitTransition: self
]

{ #category : 'adding' }
FBTransition >> addTo: aFBNode [
	source := aFBNode.
	aFBNode addOutgoing: self.
	^ target
]

{ #category : 'as yet unclassified' }
FBTransition >> attach [ 
	source addOutgoing: self.
	target addIncoming: self.
]

{ #category : 'accessing' }
FBTransition >> condition [
	^ condition 
]

{ #category : 'accessing' }
FBTransition >> condition: anObject [

	condition := anObject 
]

{ #category : 'testing' }
FBTransition >> conditionMatches: anObject [
	condition ifNil: [ ^ true ].
	^ condition value: anObject 
]

{ #category : 'as yet unclassified' }
FBTransition >> detach [ 
	source removeOutgoing: self.
	target removeIncoming: self.
]

{ #category : 'testing' }
FBTransition >> hasCondition [
	^ condition notNil
]

{ #category : 'accessing' }
FBTransition >> id [

	^ id
]

{ #category : 'initialization' }
FBTransition >> initialize [ 
	super initialize.
	id := FBIdGenerator current newId
]

{ #category : 'printing' }
FBTransition >> printOn: aStream [ 
	source printOn: aStream.
	aStream << ' --> '.
	target printOn: aStream
]

{ #category : 'accessing' }
FBTransition >> resultName [
    ^ resultName
]

{ #category : 'accessing' }
FBTransition >> resultName: aSymbol [
    resultName := aSymbol
]

{ #category : 'executing' }
FBTransition >> resumeIn: anExecutor withToken: aToken value: aValue [
	"I was suspended instead of followed, because my target only proceeds on an explicit
	trigger (FBBaseActivation>>followTransition:withToken:). My target therefore has no
	activation yet, and the impulse is its input: it gets a fresh activation carrying
	aValue as its argument and is activated now, exactly as FBFlowExecutor>>step would
	have done had no trigger been required.

	aToken is the token my target would have been activated with. Without it the fresh
	activation carries a default token with no #splitId, and a join behind me opens a
	second FBJoinState that never reaches its expected count - see
	FBBaseActivation>>waitForNode:withToken:. Answers the fresh activation"

	| activation |
	activation := anExecutor newActivation: self.
	aToken ifNotNil: [ :token |
		activation token: token.
		"the step that parked me was my source's: it marked its own token #waiting
		(FBBaseActivation>>waitForNode:withToken:), and aToken is that token's child.
		A token persisted before #parent was a reference stops the walk, and the source
		keeps its mark - as it did all along"
		token parent ifNotNil: [ :parked | parked resumed ] ].
	activation argument: aValue.
	anExecutor activate: activation.
	^ activation
]

{ #category : 'accessing' }
FBTransition >> waitingNode [
	"the node that waits while I am suspended: my target, which was not activated because
	it requires a trigger. Counterpart of FBNode>>waitingNode - #suspended holds both
	kinds of waiting spot, so whoever asks something of the waiting node has to ask the
	suspension for it rather than test what it is. Two askers so far:
	FBBaseActivation>>waitForNode:withToken:, which asks it whether the wait should be
	reachable from outside, and ApptiveGrid, which reads it off an entry's #suspension to
	build a form link (see FBWaitingEntry)"
	^ target
]

{ #category : 'accessing' }
FBTransition >> source [
	^ source
]

{ #category : 'accessing' }
FBTransition >> source: aFBNode [
	source := aFBNode
]

{ #category : 'accessing' }
FBTransition >> target [
	^ target
]

{ #category : 'accessing' }
FBTransition >> target: aFBNode [
	target := aFBNode
]

{ #category : 'accessing' }
FBTransition >> transition [
	"duck-types as an FBWorkItem so callers of pending/isCreated stay usable on a
	pending queue persisted before FBWorkItem was introduced, which still holds raw
	transitions. Every executor queues work items now, so this is only that
	backwards path"
	^ self
]
