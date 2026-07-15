Class {
	#name : 'FBSimpleMerge',
	#superclass : 'FBMergeGateway',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBSimpleMerge class >> typeName [

	^ #simpleMerge
]

{ #category : 'accessing' }
FBSimpleMerge >> defaultBehaviorClass [
	^ FBSimpleMergeBehavior
]
