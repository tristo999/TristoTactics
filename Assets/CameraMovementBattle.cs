using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovementBattle : MonoBehaviour {

    public float speed = .5f;
    public bool cameraMoveEnabled = true;
    private int theScreenWidth;
    private int theScreenHeight;
    public int boundary = 50;
    public bool gamePause;
	// Use this for initialization
	void Start () {
        Cursor.lockState = CursorLockMode.Confined;
        theScreenWidth = Screen.width;
        theScreenHeight = Screen.height;
    }
	
	// Update is called once per frame
	void Update () {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            if (Cursor.lockState == CursorLockMode.Confined) {
                Cursor.lockState = CursorLockMode.None;
            } else
            {
                Cursor.lockState = CursorLockMode.Confined;
            }
        }
        if (cameraMoveEnabled)
        {
            if (Input.GetKey(KeyCode.W))
            {
                transform.position = Vector3.MoveTowards(transform.position, new Vector3(transform.position.x, transform.position.y + speed, transform.position.z), 10000);
            }
            if (Input.GetKey(KeyCode.A))
            {
                transform.position = Vector3.MoveTowards(transform.position, new Vector3(transform.position.x - speed, transform.position.y, transform.position.z), 10000);
            }
            if (Input.GetKey(KeyCode.S))
            {
                transform.position = Vector3.MoveTowards(transform.position, new Vector3(transform.position.x, transform.position.y - speed, transform.position.z), 10000);
            }
            if (Input.GetKey(KeyCode.D))
            {
                transform.position = Vector3.MoveTowards(transform.position, new Vector3(transform.position.x + speed, transform.position.y, transform.position.z), 10000);
            }   

            if (Input.mousePosition.x > theScreenWidth - boundary)
            {
                transform.position = Vector3.MoveTowards(transform.position, new Vector3(transform.position.x + speed, transform.position.y, transform.position.z), 10000);
            }
            if (Input.mousePosition.x < 0 + boundary)
            {
                transform.position = Vector3.MoveTowards(transform.position, new Vector3(transform.position.x - speed, transform.position.y, transform.position.z), 10000);
            }
            if (Input.mousePosition.y > theScreenHeight - boundary)
            {
                transform.position = Vector3.MoveTowards(transform.position, new Vector3(transform.position.x, transform.position.y + speed, transform.position.z), 10000);
            }
            if (Input.mousePosition.y < 0 + boundary)
            {
                transform.position = Vector3.MoveTowards(transform.position, new Vector3(transform.position.x, transform.position.y - speed, transform.position.z), 10000);
            }
        }
    }
}
