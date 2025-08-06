
class Bucket:
    def __init__(self, name, lat, long):
        self.name = name
        self.lat = lat
        self.long = long

    def __repr__(self):
        return f"Bucket(name={self.name}, lat={self.lat}, long={self.long})"