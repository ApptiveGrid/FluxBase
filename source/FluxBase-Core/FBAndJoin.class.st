Class {
	#name : 'FBAndJoin',
	#superclass : 'FBMergeGateway',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBAndJoin class >> typeName [

	^ #andJoin
]

{ #category : 'as yet unclassified' }
FBAndJoin >> defaultBehaviorClass [
	^ FBJoinBehavior
]
