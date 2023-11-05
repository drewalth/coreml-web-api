
# TODO: move this to a build phase
compile_ml_model:
	cd server/MLModelSource && \
	xcrun coremlcompiler compile Resnet50.mlmodel ../Sources/App/Resources && \
	xcrun coremlcompiler generate Resnet50.mlmodel ../Sources/App/Resources --language Swift

pretty:
	swiftformat . --swiftversion 5

.PHONY: clean_xcode

DERIVED_DATA_DIR := $(HOME)/Library/Developer/Xcode/DerivedData

# delete and replace the DerivedData directory
clean_xcode:
	@echo "Cleaning Xcode DerivedData..."
	@rm -rf $(DERIVED_DATA_DIR)
	@mkdir $(DERIVED_DATA_DIR)
	@echo "Xcode DerivedData has been cleaned and reset."
