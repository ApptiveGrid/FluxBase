"
A condition wait that is also reachable from outside, used to exercise the registration
in FBBaseActivation>>waitForNode:withToken: for the node-shaped waiting spot. The two
hooks are independent: FBPluggableWait already parks on a condition, this one adds that
the wait has a waker outside the image - a wait for a date that can also be triggered by
hand. FluxBase-Core models no such node, so tests need a stand-in here, the way
FBTriggerTask stands in for the transition-shaped case.

Inherits FBWaitForCondition's #isAbstract, so it stays out of the exposed node set that
FBMergeGatewayTest>>testAllExposedNodeClassesHaveATypeName walks - a test stand-in, not
a node type users can pick.
"
Class {
	#name : 'FBExternalWait',
	#superclass : 'FBPluggableWait',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'testing' }
FBExternalWait >> isExternallyResumable [

	^ true
]
