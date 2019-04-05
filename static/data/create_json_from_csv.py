import pandas as pd

df = pd.read_csv("./dummy_data.csv")

df.to_json("./dummy_data.json",orient = "records")