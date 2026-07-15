Class {
	#name : 'FBMultiChoiceGateway',
	#superclass : 'FBSplitGateway',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBMultiChoiceGateway class >> typeName [

	^ #multiChoiceGateway
]

{ #category : 'accessing' }
FBMultiChoiceGateway >> defaultBehaviorClass [
	^ FBMultiChoiceGatewayBehavior
]
