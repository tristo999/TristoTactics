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
    public float autoSpeed = 4f;
    Vector3 newPosition;
    public GameObject pauseMenu;
    public RoundController roundController;
	// Use this for initialization
	void Start () {
        Cursor.lockState = CursorLockMode.Confined;
        theScreenWidth = Screen.width;
        theScreenHeight = Screen.height;
        pauseMenu = GameObject.FindGameObjectWithTag("PauseScreen");
        roundController = GameObject.FindGameObjectWithTag("GameController").GetComponent<RoundController>();
        pauseMenu.SetActive(false);
    }
	
	// Update is called once per frame
	void Update () {
        // Refactor so menu button controls pause instead of escape key
        /*
            if (Input.GetKeyDown(KeyCode.Escape))
            {
                if (Cursor.lockState == CursorLockMode.Confined)
                {
                    Cursor.lockState = CursorLockMode.None;
                    gamePause = true;
                    roundController.gamePause = true;
                    pauseMenu.SetActive(true);
                }
                else
                {
                    Cursor.lockState = CursorLockMode.Confined;
                    gamePause = false;
                    pauseMenu.SetActive(false);
                    roundController.gamePause = false;
                }
            }
            */
        if (!gamePause)
        {
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
            else
            {
                if (transform.position.x == newPosition.x && transform.position.y == newPosition.y)
                {
                    cameraMoveEnabled = true;
                }
                else
                {
                    transform.position = Vector3.MoveTowards(transform.position, new Vector3(newPosition.x, newPosition.y, transform.position.z), autoSpeed);
                }
            }
        }
    }

    public void moveCamera(Vector3 newPos)
    {
        newPosition = newPos;
        cameraMoveEnabled = false;
    }
    public void pauseGame()
    {
        if (!gamePause)
        {
            Cursor.lockState = CursorLockMode.None;
            gamePause = true;
            roundController.gamePause = true;
            pauseMenu.SetActive(true);
        }
        else
        {
            Cursor.lockState = CursorLockMode.Confined;
            gamePause = false;
            pauseMenu.SetActive(false);
            roundController.gamePause = false;
        }
    }
    
    public void exitApplication()
    {
        Application.Quit();
    }

}
