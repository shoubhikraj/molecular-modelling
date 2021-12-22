Sample training data for spectral prediction. Each molecule has 732 features. Created by generating 2048 bit hashed fingerprints, and then appending the dielectric constant(epsilon) of the solvent at the end (now 2049 features), then removing features that have zero variance.

To load the data, from python:

```python
import numpy as np
X_train = np.loadtxt('X_train.txt')
y_train = np.loadtxt('y_train.txt')
```

Arrays given in scikit-learn format, i.e. for X_train, each row has features for one molecule. But y_train is a single row array, containing targets for all molecules.
