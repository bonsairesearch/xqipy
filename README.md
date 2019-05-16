# xqipy 

`xqipy' is a Python library for calculating various Quality Indicators developed by AHRQ such as PQI, IQI, PSI, PDI.

## Installing

Installing from the source:
```
$ git clone git@github.com:yubin-park/xqipy.git
$ cd xqipy
$ python setup.py develop
```

Or, simply using `pip`:
```
$ pip install xqipy
```

## File Structure
- `xqipy/`: The package source code is located here.
  - `data/`: The raw data files downloaded from [the AHRQ website](https://www.qualityindicators.ahrq.gov/Software/Default.aspx). 
  - `utils.py`: A module for readings data files
- `tests/`: test scripts to check the validity of the outputs.
- `LICENSE.txt`: Apache 2.0.
- `README.md`: This README file.
- `setup.py`: a set-up script.

## Code Examples
`xqipy` is really simple to use. 
Please see some examples below.
NOTE that all functions used below have docstrings. 
If you want to see the input parameter specifications,
please type `print(<instance>.<function>.__doc__)`.

```python
TBD
```

Please refer to the test scripts under the `tests/` folder if you want to see other example use cases.

## License
Apache 2.0

## Authors
Yubin Park, PhD

## References
- https://www.qualityindicators.ahrq.gov/Software/Default.aspx
- https://www.qualityindicators.ahrq.gov/Modules/pqi_resources.aspx




