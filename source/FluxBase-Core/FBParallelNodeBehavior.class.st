Class {
	#name : 'FBParallelNodeBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBParallelNodeBehavior >> execute [
	| executor |
	(activation argument isCollection and: [
		 activation argument isSequenceable ]) ifFalse: [
		FBError signal:
			'Input for parallel execution has to be a non empty collection.' ].
	"the input this node iterates. written before the outgoing guard below, since a node
	with no loop body never gets an executor and its output still has to answer something
	(FBFlowTest>>testParallelNodeAsLastNodeHasOutput). while a scope of its own is open
	the node's output comes from that scope's #list and #index instead - this is only
	what is left to answer from once it is closed, read back through
	FBBaseActivation>>currentValue rather than #value"
	activation argument ifNotEmpty: [ :input | activation value: input first ].
	activation node outgoing notEmpty ifFalse: [ ^ self ].
	executor := FBParallelExecutor new
		node: activation node;
		list: activation argument.
	activation flowInstance pushExecutor: executor.
	"an empty input has no iteration to step: the scope completes at once, with an empty
	result, and the flow goes on behind the loop's join (FBParallelExecutor>>completeScope)
	- it used to end here, silently, with the fork left #created"
	activation argument ifEmpty: [ executor continue ]
]
