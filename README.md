# dxIDEPackage_TDataSetVisualizer
Delphi IDE Debug Visualizer to view a TDataSet descendant within a DBGrid.

Built with Delphi 10 Seattle, but likely compatible with Delphi 2010 and above.


![Screenshot](https://raw.githubusercontent.com/darianmiller/dxWikiArtifacts/master/dxIDEPackage_TDataSetVisualizer/DebugVisualizerExampleScreen.png)


Usage note: When this visualizer is used on a TDataSet expression, the debugger calls {Expression}.SaveToFile() to save the dataset to a temporary file, then creates a TDataSet descendant dataset based on the supported expression type (currently ADO, FireDAC, and ClientDataSet) and then calls TempDataset.LoadFromFile() to retrieve the data.

This obviously means that you likely shouldn't use this visualizer on very large datasets, or those datasets which may contain privileged information.  Perhaps less obvious, this also means for FireDAC applications, the dataset within your debugged executable needs to be able to support the .SaveToFile method which is enabled in FireDAC by including a unit that supports a particular TFDStanStorageXxxLink component within your application.  In other words, if you get an error viewing a FireDAC dataset, a simple work around is to include "FireDAC.Stan.StorageBin" within a Uses clause of a unit within your debugged applcation.  You likely will also have to include a call to the .SaveToFile method within your executable so the linker doesn't exclude it.
