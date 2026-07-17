Class {
	#name : 'FBOrJoin',
	#superclass : 'FBMergeGateway',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBOrJoin class >> typeName [

	^ #orJoin
]

{ #category : 'as yet unclassified' }
FBOrJoin >> defaultBehaviorClass [
	^ FBJoinBehavior
]
