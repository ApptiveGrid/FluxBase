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

{ #category : 'testing' }
FBPluggableTask class >> isAbstract [

	^ true
]

{ #category : 'instance creation' }
FBPluggableTask >> activateWith: anActivation [

	block cull: anActivation.
	anActivation done.
	anActivation followAllOutgoing.

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
FBPluggableTask >> produces: anObject [
	"configure me to hand out anObject as my result whenever I run - the constant sibling
	of #evaluateTo:, which produces the value of a script instead. Used to be #value:,
	which read as if it set a result; it sets what the task is to do"
	block := [ :activation | activation value: anObject ]
]
