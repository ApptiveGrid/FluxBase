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

	executor := anActivation instance parallelExecutorFrom: self ifAbsent: [
		"no executor was ever pushed for this node - either the input collection was empty, or
		the node has no outgoing transition (no loop body was ever entered, see
		FBParallelNodeBehavior>>execute). fall back to the raw activation value in that case,
		unwrapping a collection to its first element to match the with-executor convention above"
		| v |
		v := anActivation value.
		^ (v isCollection and: [ v isSequenceable and: [ v isString not ] ])
			  ifTrue: [ v ifEmpty: [ nil ] ifNotEmpty: [ :notEmpty | notEmpty first ] ]
			  ifFalse: [ v ] ].
	^ executor outputFor: anActivation
]
