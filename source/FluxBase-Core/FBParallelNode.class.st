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
FBParallelNode >> outputFor: anActivation [
	"unlike other nodes, the parallel node output return the current input value being processed.
	if no execution in progress, returns the first element of the input value"

	| executor |
	
	executor := anActivation instance parallelExecutorFrom: self ifAbsent: ["if there was no input, there was no output for the parallel node"^ nil].
	^ executor outputFor: anActivation
]
