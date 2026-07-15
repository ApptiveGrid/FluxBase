Class {
	#name : 'FBActivationMetadataTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBActivationMetadataTest >> testMetadataAtPutIsAccessibleAtGet [
	| flow instance task |
	flow := FBFlow simpleFlow.
	instance := flow newInstance.
	instance executeWith: 7.
	task := instance activationOfNode: (flow start outgoing first target).

	task metadataAt: #status put: 200.

	self assert: (task metadataAt: #status) equals: 200.
	self assert: task metadata class equals: FBActivationMetadata
]

{ #category : 'tests' }
FBActivationMetadataTest >> testPreviousReturnsMetadataOfPriorActivation [
	| flow instance taskActivation endActivation |
	flow := FBFlow simpleFlow.
	instance := flow newInstance.
	instance executeWith: 7.
	taskActivation := instance activationOfNode: (flow start outgoing first target).
	endActivation := instance activationOfNode: flow end.

	taskActivation metadataAt: #status put: 'ok'.
	endActivation metadataAt: #seen put: true.

	self assert: endActivation metadata previous equals: taskActivation metadata
]
