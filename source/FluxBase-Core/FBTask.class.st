Class {
	#name : 'FBTask',
	#superclass : 'FBNode',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBTask class >> isAbstract [

	^ self == FBTask
]

{ #category : 'accessing' }
FBTask >> defaultBehaviorClass [
	^ FBTaskBehavior
]
