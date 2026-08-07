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
	"executor is this activation's *creating* executor - correct to ask
	directly for a plain task's output (it was created inside that
	executor's own scope, one slot per that scope's iteration). but when
	this activation is a parallel node's own self-activation and that node
	is itself nested inside an outer parallel scope, executor is the
	*outer* scope that created it, not the freshly-pushed inner executor
	that actually tracks this node's own iteration - so it must be
	resolved through the node instead, the same way FBBaseActivation>>output
	does, to reach the right (inner) executor via #parallelExecutorFrom:
	(see FBParallelNode>>outputFor: and the 'parallel node in parallel
	node' bug)"
	(self node isKindOf: FBParallelNode) ifTrue: [ ^ self node outputFor: self ].
	"a join node's own activation is not a parallel/split node, so it never
	goes through FBParallelNode>>outputFor:'s #parallelExecutorFrom: lookup
	above - by the time it's done, #value (values, aliased to arguments by
	FBParallelJoinNodeBehavior>>execute) already *is* the aggregated result,
	needing no further executor-based resolution regardless of nesting"
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
