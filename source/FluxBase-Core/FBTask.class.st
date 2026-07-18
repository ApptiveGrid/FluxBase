Class {
	#name : 'FBTask',
	#superclass : 'FBNode',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBTask >> defaultBehaviorClass [
	^ FBTaskBehavior
]
