"
I am where an FBRemoteFlowCall goes, and where the locator of its callback address comes
from. FluxBase knows nothing about transport - HTTP, a queue, a process on the same
machine - so a port is what an environment plugs into an FBRemoteFlowTask.

	locator		the routing part of every callback address handed out through me:
			how the other side finds its way back to this machine
	dispatch:	send one call; the result comes back on its own, later, as
			FBFlowInstance>>signal:with: on the call's correlationId

FBPluggableDispatchPort is the one for tests.
"
Class {
	#name : 'FBRemoteDispatchPort',
	#superclass : 'Object',
	#category : 'FluxBase-Core',
	#package : 'FluxBase-Core'
}

{ #category : 'dispatching' }
FBRemoteDispatchPort >> dispatch: aRemoteFlowCall [
	self subclassResponsibility
]

{ #category : 'accessing' }
FBRemoteDispatchPort >> locator [
	self subclassResponsibility
]
