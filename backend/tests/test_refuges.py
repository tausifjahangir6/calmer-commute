def test_refuges_are_ranked_from_arrival_coordinates(client):
    response = client.get("/api/refuges?latitude=-37.8183&longitude=144.9671&limit=2")
    body = response.get_json()

    assert response.status_code == 200
    assert len(body["refuges"]) == 2
    assert body["arrival"] == {"latitude": -37.8183, "longitude": 144.9671}
    assert body["refuges"][0]["distance_metres"] <= body["refuges"][1]["distance_metres"]
    assert body["refuges"][0]["verification_status"] == "candidate_not_verified"


def test_invalid_refuge_coordinates_are_rejected(client):
    response = client.get("/api/refuges?latitude=200&longitude=144.9")

    assert response.status_code == 400
    assert response.get_json()["error"]["code"] == "validation_error"

