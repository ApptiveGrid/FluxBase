Class {
	#name : 'FBParallelActivation',
	#superclass : 'FBBaseActivation',
	#instVars : [
		'values',
		'arguments',
		'metadata'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBParallelActivation >> argument [ 
	^ arguments at: executor index
]

{ #category : 'accessing' }
FBParallelActivation >> argument: anObject [ 
	arguments at: executor index put: anObject 
]

{ #category : 'accessing' }
FBParallelActivation >> arguments [
	^ arguments
]

{ #category : 'accessing' }
FBParallelActivation >> done [

	"the parallel activation is done only after processing the last elements of the input list"
	executor isLastIndex ifTrue: [ 
		super done
		 ]
]

{ #category : 'accessing' }
FBParallelActivation >> currentValue [
	"the counterpart of #value:, which writes values at: executor index while #value
	answers the whole per-iteration array - executor being this activation's *creating*
	executor, i.e. the enclosing scope, exactly as for #argument"

	^ values at: executor index
]

{ #category : 'initialization' }
FBParallelActivation >> initializeValues: anInteger [

	arguments := Array new: anInteger.
	values := Array new: anInteger.
	metadata := Array new: anInteger.
]

{ #category : 'as yet unclassified' }
FBParallelActivation >> metadataAt: key ifAbsent: aBlock [

	^ (self metadataAtIndex: executor index) at: key 
		ifAbsent: aBlock
]

{ #category : 'as yet unclassified' }
FBParallelActivation >> metadataAt: key put: anObject [ 

	(self metadataAtIndex: executor index) at: key 
		put: anObject
]

{ #category : 'as yet unclassified' }
FBParallelActivation >> metadataAtIndex: index [

	^ (metadata at: index) ifNil: [
		  metadata at: index put: (FBActivationMetadata new
				   schema: self metadataSchema;
				   activation: self;
				   yourself) ]
]

{ #category : 'initialization' }
FBParallelActivation >> metadataSchema [
	^ node metadataSchema
]

{ #category : 'accessing' }
FBParallelActivation >> output [
	"executor is this activation's *creating* executor - correct to ask directly for a
	plain task's output, which was created inside that executor's own scope and has one
	slot per that scope's iteration. the two node kinds that are not such a task have to
	be answered without it.

	a parallel node's own self-activation: asking the creating executor would ask the
	*enclosing* scope, not the one this node itself opened. the node resolves it against
	the scope it opened itself instead (see FBParallelNode>>outputFor:).

	a join node's own activation: by the time it is done, #value (aliased to arguments by
	FBParallelJoinNodeBehavior>>execute) already *is* the aggregated result, so it needs
	no per-iteration resolution regardless of nesting"
	(self node isKindOf: FBParallelNode) ifTrue: [ ^ self node outputFor: self ].
	(self node isKindOf: FBParallelJoinNode) ifTrue: [ ^ self value ].
	^ executor outputFor: self
]

{ #category : 'printing' }
FBParallelActivation >> printOn: aStream [ 
	aStream << 'parallel activation: '.
	node printOn: aStream.
	aStream << ', arguments: '.
	arguments printOn: aStream.
	aStream << ', values: '.
	values printOn: aStream 
	
]

{ #category : 'evaluating' }
FBParallelActivation >> value [
	^ values
]

{ #category : 'accessing' }
FBParallelActivation >> value: anObject [ 
	values at: executor index put: anObject 
]

{ #category : 'accessing' }
FBParallelActivation >> values: aCollection [ 
	values := aCollection
]
