#import <AudioToolbox/AudioToolbox.h>
#import <arpa/inet.h>
#import <substrate.h>
#define ASSPort 43333

AudioBufferList *p_bufferlist = NULL;
float *empty = NULL;

OSStatus (*AudioUnitRender_orig)(AudioUnit unit, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData);
OSStatus AudioUnitRender_hook(AudioUnit unit, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    AudioComponentDescription unitDescription = {0};
    AudioComponentGetDescription(AudioComponentInstanceGetComponent(unit), &unitDescription);
    
    if (unitDescription.componentSubType == 'mcmx') {
        if (inNumberFrames > 0) {
            p_bufferlist = ioData;
        } else {
            p_bufferlist = NULL;
        }
    }

    return AudioUnitRender_orig(unit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, ioData);
}

void server()
{
    NSLog(@"[ASS] Server created...");
    struct sockaddr_in local;
    local.sin_family = AF_INET;
    local.sin_addr.s_addr = htonl(INADDR_LOOPBACK); //INADDR_ANY if you want to expose audio output
    local.sin_port = htons(ASSPort);
    int listenfd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);

    int r = -1;
    while(r != 0) {
        r = bind(listenfd, (struct sockaddr*)&local, sizeof(local));
        usleep(200 * 1000);
    }
    NSLog(@"[ASS] Bound");

    int one = 1;
    setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
    setsockopt(listenfd, SOL_SOCKET, SO_REUSEPORT, &one, sizeof(one));
    setsockopt(listenfd, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof(one));

    r = -1;
    while(r != 0) {
        r = listen(listenfd, 20);
        usleep(200 * 1000);
    }
    NSLog(@"[ASS] Listening");

    while(true) {
        int connfd = accept(listenfd, (struct sockaddr*)NULL, NULL);
        if (connfd > 0) {
            setsockopt(connfd, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof(one));
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UInt32 len = sizeof(float);
                int rlen = 0;
                float *data = NULL;
                char buffer[128];

                while(true) {
                    if (connfd == -1) break;
                    rlen = recv(connfd, buffer, sizeof(buffer), 0); //accept anything from the client and send data back
                    if (rlen <= 0) {
                        if (rlen == 0) {
                            close(connfd);
                        }
                        break;
                    }
                    data = NULL;

                    if (p_bufferlist != NULL && (*p_bufferlist).mNumberBuffers > 0 && (*p_bufferlist).mNumberBuffers < 9) { //this is hacky but it gets the job done
                        len = (*p_bufferlist).mBuffers[0].mDataByteSize;
                        if (len > 4000 && len < 70000 && len % sizeof(float) == 0) {
                            data = (float *)(*p_bufferlist).mBuffers[0].mData;
                            if (data[0] > 1.5 || data[0] < -1.5) {
                                data = NULL;
                            }
                        }
                    }

                    if (data == NULL) {
                        len = sizeof(float);
                        data = empty;
                    }

                    rlen = send(connfd, &len, sizeof(UInt32), 0);
                    if (rlen > 0) {
                        rlen = send(connfd, data, len, 0);
                    }
                    
                    if (rlen <= 0) {
                        if (rlen == 0) {
                            close(connfd);
                        }
                        break;
                    }
                }
            });
        }
    }
}

%ctor {
    empty = (float *)malloc(sizeof(float));
    empty[0] = 0.0f;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        server();
    });
    MSHookFunction(AudioUnitRender, AudioUnitRender_hook, &AudioUnitRender_orig);
}