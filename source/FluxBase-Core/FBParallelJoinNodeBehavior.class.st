Class {
	#name : 'FBParallelJoinNodeBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'execution' }
FBParallelJoinNodeBehavior >> execute [
	| executor |
	executor := activation flowInstance executor.
	executor atEnd ifTrue: [
		executor popThenResume: [
			activation values: activation arguments.
			activation followAllOutgoing ] ]
]
