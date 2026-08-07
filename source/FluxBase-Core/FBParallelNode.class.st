Class {
	#name : 'FBParallelNode',
	#superclass : 'FBTask',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBParallelNode class >> isAbstract [

	^ true
]

{ #category : 'accessing' }
FBParallelNode >> activationClass [
	^ FBParallelActivation  
]

{ #category : 'accessing' }
FBParallelNode >> defaultBehaviorClass [
	^ FBParallelNodeBehavior
]

{ #category : 'accessing' }
FBParallelNode >> impliedJoinNodeClass [
	"the join class synthesized to implicitly close this node's own scope
	when nothing explicit follows its branch (see
	FBParallelExecutor>>buildImpliedContinuationNode). ApptiveBase's
	AGParallelNode overrides this to answer AGParallelJoinNode instead"

	^ FBParallelJoinNode
]

{ #category : 'accessing' }
FBParallelNode >> outputFor: anActivation [
	"unlike other nodes, the parallel node output return the current input value being processed.
	if no execution in progress, returns the first element of the input value"

	| executor |
	
	executor := anActivation instance parallelExecutorFrom: self ifAbsent: ["if there was no input, there was no output for the parallel node"^ nil].
	^ executor outputFor: anActivation
]
