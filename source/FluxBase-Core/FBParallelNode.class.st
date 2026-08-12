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
	"unlike other nodes, a parallel node previews the input it iterates rather than a
	result: the element it is on right now, or - once nothing is in progress - the first
	element of that input.

	while its own scope is open the running executor is the single source of that: its
	#list and #index are the loop. no copy of the item is kept anywhere, and the executor
	answered is always the open one, because FBFlowInstance>>executors is the live stack.

	once the scope is closed, or was never opened at all (empty input, or no loop body -
	see FBParallelNodeBehavior>>execute), fall back to what the behavior recorded. that is
	read through #currentValue and not #value: for an activation reused across the
	iterations of an enclosing parallel scope, #value: wrote a single slot while #value
	answers the whole array, and unwrapping the array by one level is right for a slot
	holding a single element (FluxBase) but one level short for a slot holding the whole
	collection (AGParallelNodeBehavior, whose collection may come from the #collection
	script property and so cannot be recovered from #argument)"

	| input |
	(anActivation instance parallelExecutorFrom: self ifAbsent: [ nil ])
		ifNotNil: [ :scope | ^ scope outputFor: anActivation ].
	input := anActivation currentValue.
	^ (input isCollection and: [ input isSequenceable and: [ input isString not ] ])
		  ifTrue: [ input ifEmpty: [ nil ] ifNotEmpty: [ :notEmpty | notEmpty first ] ]
		  ifFalse: [ input ]
]

