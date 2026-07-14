Class {
	#name : 'FBPluggableTask',
	#superclass : 'FBTask',
	#instVars : [
		'block'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBPluggableTask >> activateWith: anActivation [

	block cull: anActivation.
	anActivation done.
	anActivation followAll: self outgoing.

]

{ #category : 'accessing' }
FBPluggableTask >> block [

	^ block
]

{ #category : 'accessing' }
FBPluggableTask >> block: anObject [

	block := anObject
]

{ #category : 'as yet unclassified' }
FBPluggableTask >> evaluateTo: aString [ 
	self
		block: [ :activation |
			activation value: (activation asScriptScopeDuring: [ :scope |  aString asApptiveScript valueIn: scope ]) ]
]

{ #category : 'initialization' }
FBPluggableTask >> initialize [ 
	super initialize.
	block := [  ]
]

{ #category : 'accessing' }
FBPluggableTask >> value: anInteger [ 
	block := [ :activation | activation value: anInteger  ]
]
