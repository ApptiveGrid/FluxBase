"
A stand-in for a subclass of FBRemoteFlowTask that does not send its argument as the
remote flow's input but assembles the input from a configuration of its own - the way
ApptiveGrid's task maps fields onto the remote flow's schema. Inherits #isAbstract, so it
stays out of the exposed node set, like the other test stand-ins.
"
Class {
	#name : 'FBRemoteFlowTaskAssemblingItsInput',
	#superclass : 'FBRemoteFlowTask',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'accessing' }
FBRemoteFlowTaskAssemblingItsInput >> inputValueFor: anActivation [
	^ { #amount -> anActivation argument. #currency -> 'EUR' } asDictionary
]
