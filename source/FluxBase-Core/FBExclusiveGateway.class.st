Class {
	#name : 'FBExclusiveGateway',
	#superclass : 'FBGateway',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBExclusiveGateway class >> typeName [

	^ #exclusiveGateway
]

{ #category : 'accessing' }
FBExclusiveGateway >> defaultBehaviorClass [
	^ FBExclusiveGatewayBehavior 
]
