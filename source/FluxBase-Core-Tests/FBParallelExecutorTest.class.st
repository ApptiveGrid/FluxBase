Class {
	#name : 'FBParallelExecutorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBParallelExecutorTest >> testAddPendingWithTokenIsIgnoredAndTransitionIsAddedRaw [
	| executor transition |
	executor := FBParallelExecutor new
		flowInstance: FBFlow simpleFlow newInstance;
		node: (FBParallelNode named: 'p');
		yourself.
	transition := FBTransition new.
	executor addPending: transition withToken: FBToken new.
	self assert: executor pending last class equals: FBTransition.
	self assert: executor pending last == transition
]
