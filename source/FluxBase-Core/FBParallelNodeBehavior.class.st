Class {
	#name : 'FBParallelNodeBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBParallelNodeBehavior >> execute [

	(activation argument isCollection and: [
		 activation argument isSequenceable ]) ifFalse: [
		FBError signal:
			'Input for parallel execution has to be a non empty collection.' ].
	(activation argument size > 0 and: [ activation node outgoing notEmpty ]) ifFalse: [ ^ self ].
	activation flowInstance pushExecutor: (FBParallelExecutor new
			 node: activation node;
			 list: activation argument).
	self flag: #todo.
	"this is a hack to allow a frontend to determine which will be the payload
	when the parallel node runs the loop. This should not be the output but an 
	extra property"
	activation value: activation argument first.
	
]
