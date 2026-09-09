"
A dispatch port for tests and stand-ins: a fixed locator, and a block that gets every
call. The block may resume the instance itself, the way a same-image remote would.
"
Class {
	#name : 'FBPluggableDispatchPort',
	#superclass : 'FBRemoteDispatchPort',
	#instVars : [
		'locator',
		'block'
	],
	#category : 'FluxBase-Core',
	#package : 'FluxBase-Core'
}

{ #category : 'dispatching' }
FBPluggableDispatchPort >> dispatch: aRemoteFlowCall [
	block cull: aRemoteFlowCall
]

{ #category : 'initialization' }
FBPluggableDispatchPort >> initialize [
	super initialize.
	block := [ :call | ]
]

{ #category : 'accessing' }
FBPluggableDispatchPort >> locator [
	^ locator
]

{ #category : 'accessing' }
FBPluggableDispatchPort >> locator: aString [
	locator := aString
]

{ #category : 'accessing' }
FBPluggableDispatchPort >> onDispatch: aBlock [
	block := aBlock
]
