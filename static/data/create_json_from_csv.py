import pandas as pd

df = pd.read_csv("./beta_frame.csv")

df.to_json("./beta_frame.json",orient = "records")