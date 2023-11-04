
# TODO: move this to a build phase
compile_ml_model:
	cd server/MLModelSource && \
	xcrun coremlcompiler compile Resnet50.mlmodel . && \
	xcrun coremlcompiler generate Resnet50.mlmodel ../Sources/App/MLModel --language Swift

pretty:
	swiftformat . --swiftversion 5
