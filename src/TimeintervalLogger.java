package ch.ethz.asltest;

import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;

public class TimeintervalLogger extends TimerTask {
    private Timer timer;
    // private long firstTimestamp = -1;                    // Timestamp when request became readable in middleware
    // private long timestampQueueEntered = -1;                // Timestamp when entering the queue
    private int numRequests = 0;
    private int queueLengthSum = 0;             // Size of queue before this request was added to it by networkerThread
    private long queueWaitingTimeSum = -1;                     // Time in ms waiting in queue
    private long timeServerProcessingSum = -1;                 // Time in ms for memcached servers to process request
    private long timeInMiddlewareSum = -1;                     // Time in 1/10 ms the request spent in middleware
    private int numMissesOnServerSum = -1;  
    private int numGetRequests = 0;
    private int numSetRequests = 0;
    private int numKeysSum = 0;

    public TimeintervalLogger(Timer timer) {
        this.timer = timer;

    }

    @Override
    public void run() {
        System.out.println("Timer task started at:"+new Date());
        aggregate();
        System.out.println("Timer task finished at:"+new Date());
    }

    private void aggregate() {
        try {
            //assuming it takes 20 secs to complete the task
            Thread.sleep(20000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
    
    public static void main(String args[]){
        /*TimerTask timerTask = new MyTimerTask();
        //running timer task as daemon thread
        Timer timer = new Timer(true);
        timer.scheduleAtFixedRate(timerTask, 0, 10*1000);
        System.out.println("TimerTask started");
        //cancel after sometime
        try {
            Thread.sleep(120000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        timer.cancel();
        System.out.println("TimerTask cancelled");
        try {
            Thread.sleep(30000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }*/
    }

}
