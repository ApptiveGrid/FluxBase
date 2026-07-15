Class {
	#name : 'FBAndSplit',
	#superclass : 'FBSplitGateway',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBAndSplit class >> typeName [

	^ #andSplit
]

{ #category : 'accessing' }
FBAndSplit >> defaultBehaviorClass [
	^ FBAndSplitBehavior
]
