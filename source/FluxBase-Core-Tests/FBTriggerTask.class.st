"
A task that only proceeds on an explicit external trigger, used to exercise
FBBaseActivation>>followTransition:withToken:'s #requiresTrigger handling. FluxBase-Core
itself models no such node - the real one is ApptiveBase's flow form - so tests need a
stand-in here.

Deliberately keeps FBPluggableTask's #isAbstract, so it stays out of the exposed node
set that FBMergeGatewayTest>>testAllExposedNodeClassesHaveATypeName walks - it is a
test stand-in, not a node type users can pick. Being abstract does not stop tests from
instantiating it, exactly as they already instantiate FBPluggableTask itself.
"
Class {
	#name : 'FBTriggerTask',
	#superclass : 'FBPluggableTask',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'testing' }
FBTriggerTask >> requiresTrigger [

	^ true
]
