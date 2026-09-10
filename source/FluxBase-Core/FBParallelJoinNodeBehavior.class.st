Class {
	#name : 'FBParallelJoinNodeBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'execution' }
FBParallelJoinNodeBehavior >> execute [
	"one arrival per iteration: my argument slot already holds this iteration's value
	(FBParallelActivation>>argument:, slotted by token). The scope closes once every
	iteration is accounted for - here, when this arrival was the last thing outstanding;
	from the executor itself when a withdrawal or a filtered iteration was
	(FBParallelExecutor>>completeScope, the one way the scope closes)"
	| executor |
	executor := activation flowInstance executor.
	executor atEnd ifTrue: [ executor completeScope ]
]
