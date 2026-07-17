Class {
	#name : 'FBParallelJoinNode',
	#superclass : 'FBTask',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBParallelJoinNode class >> isAbstract [

	^ true
]

{ #category : 'as yet unclassified' }
FBParallelJoinNode >> defaultBehaviorClass [
	^ FBParallelJoinNodeBehavior
]
