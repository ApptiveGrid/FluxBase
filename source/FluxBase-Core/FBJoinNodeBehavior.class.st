Class {
	#name : 'FBJoinNodeBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'execution' }
FBJoinNodeBehavior >> execute [ 
	| executor |
	executor := activation flowInstance currentExecutor.
	executor atEnd ifTrue: [ 
		executor stop .
		activation values: activation arguments.
		activation followAllOutgoing ]
]
