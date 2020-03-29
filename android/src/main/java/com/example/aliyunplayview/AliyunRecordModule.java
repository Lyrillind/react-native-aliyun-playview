package com.example.aliyunplayview;

import android.annotation.TargetApi;
import android.media.MediaCodec;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.os.Build;
import android.util.Log;
import com.example.aliyunplayview.util.PermissionChecker;
import com.example.aliyunplayview.util.ToastUtils;
import com.example.aliyunplayview.util.Utils;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.gson.Gson;
import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;

public class AliyunRecordModule extends ReactContextBaseJavaModule {
    private static final String TAG = "AliyunRecordModule";
    private ReactContext reactContext;
    private ByteBuffer mReadBuf;
    private int mOutAudioTrackIndex;
    private int mOutVideoTrackIndex;
    private MediaFormat mAudioFormat;
    private MediaFormat mVideoFormat;

    public AliyunRecordModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "AliyunRecordModule";
    }

    /**
     * 上传视频
     */
    @ReactMethod
    public void uploadVideo(ReadableMap params) {
        if (isPermissionOK()) {
            final String type = params.getString("type");
            String videoPath = params.getString("mp4Path");
            // String imagePath = params.getString("imagePath");
            if (videoPath.contains("file:")) {
                videoPath = videoPath.substring(7, videoPath.length());
            }
            String accessKeyId = params.getString("accessKeyId");
            String accessKeySecret = params.getString("accessKeySecret");
            String securityToken = params.getString("securityToken");
            File file = new File(videoPath);
            if (file.exists()) {
                Log.e("TAG", "视频文件存在");
            } else {
                Log.e("TAG", "视频文件不存在");
            }

            final String imagePath = Utils.getFirstFramePath(videoPath, this.reactContext);
            File imageFile = new File(imagePath);
            if (imageFile.exists()) {
                Log.e("TAG", "图片文件存在");
            } else {
                Log.e("TAG", "图片文件不存在");
            }
        }
    }

    public void sendUploadState(UploadModel uploadModel) {
        this.reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("getUploadState", new Gson().toJson(uploadModel));
    }

    public void sendProgrtessState(long progress) {
        this.reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit("getProgressState", "" + progress);
    }

    private boolean isPermissionOK() {
        PermissionChecker checker = new PermissionChecker(this.reactContext.getCurrentActivity());
        boolean isPermissionOK = Build.VERSION.SDK_INT < Build.VERSION_CODES.M || checker.checkPermission();
        if (!isPermissionOK) {
            ToastUtils.s(this.reactContext, "请给予相应的权限。");
        }
        return isPermissionOK;
    }


    /**
     * @author 何晏波
     * @QQ 1054539528
     * @date 2019/6/3
     * @function: 将多个小视频拼接为一个视频
     */
    @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    @ReactMethod
    public void mergeVideoToOneVideo(ReadableMap params, Callback successCallback) {
        final ArrayList videoPaths = (params.getArray("videoPaths")).toArrayList();
        final boolean isFront = params.getBoolean("isFront");
        String ouputFilePath = fixDegree(videoPaths, isFront);
        successCallback.invoke("file:///" + ouputFilePath);
    }


    /**
     * @author 何晏波
     * @QQ 1054539528
     * @date 2019-06-18
     * @function: 矫正视频角度
     */
    @TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    private String fixDegree(ArrayList videoPaths, boolean isFront) {
        String mOutFilename = "";
        MediaMuxer mMuxer = null;
        if (videoPaths.size() != 0) {
            String path = videoPaths.get(0).toString();
            Log.e("TAG", "拼接视频路径" + path);
            mOutFilename = path.substring(0, path.lastIndexOf("/") + 1) + new Date().getTime() + ".mp4";
        }
        mReadBuf = ByteBuffer.allocate(1048576);
        boolean getAudioFormat = false;
        boolean getVideoFormat = false;
        Iterator videoIterator = videoPaths.iterator();

        //--------step 1 MediaExtractor拿到多媒体信息，用于MediaMuxer创建文件
        while (videoIterator.hasNext()) {
            String videoPath = (String) videoIterator.next();
            MediaExtractor extractor = new MediaExtractor();

            try {
                extractor.setDataSource(videoPath);
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            int trackIndex;
            if (!getVideoFormat) {
                trackIndex = this.selectTrack(extractor, "video/");
                if (trackIndex < 0) {
                    Log.e(TAG, "No video track found in " + videoPath);
                } else {
                    extractor.selectTrack(trackIndex);
                    mVideoFormat = extractor.getTrackFormat(trackIndex);
                    getVideoFormat = true;
                }
            }

            if (!getAudioFormat) {
                trackIndex = this.selectTrack(extractor, "audio/");
                if (trackIndex < 0) {
                    Log.e(TAG, "No audio track found in " + videoPath);
                } else {
                    extractor.selectTrack(trackIndex);
                    mAudioFormat = extractor.getTrackFormat(trackIndex);
                    getAudioFormat = true;
                }
            }

            extractor.release();
            if (getVideoFormat && getAudioFormat) {
                break;
            }
        }

        try {
            mMuxer = new MediaMuxer(mOutFilename, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
            //矫正视频拼接后视频顺时针旋转
//            if (isFront) {
//                mMuxer.setOrientationHint(270);
//            } else {
//                mMuxer.setOrientationHint(90);
//            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        if (getVideoFormat) {
            mOutVideoTrackIndex = mMuxer.addTrack(mVideoFormat);
        }
        if (getAudioFormat) {
            mOutAudioTrackIndex = mMuxer.addTrack(mAudioFormat);
        }
        mMuxer.start();
        //--------step 1 end---------------------------//


        //--------step 2 遍历文件，MediaExtractor读取帧数据，MediaMuxer写入帧数据，并记录帧信息
        long ptsOffset = 0L;
        Iterator trackIndex = videoPaths.iterator();
        while (trackIndex.hasNext()) {
            String videoPath = (String) trackIndex.next();
            boolean hasVideo = true;
            boolean hasAudio = true;
            MediaExtractor videoExtractor = new MediaExtractor();

            try {
                videoExtractor.setDataSource(videoPath);
            } catch (Exception var27) {
                var27.printStackTrace();
            }

            int inVideoTrackIndex = this.selectTrack(videoExtractor, "video/");
            if (inVideoTrackIndex < 0) {
                hasVideo = false;
            }

            videoExtractor.selectTrack(inVideoTrackIndex);
            MediaExtractor audioExtractor = new MediaExtractor();

            try {
                audioExtractor.setDataSource(videoPath);
            } catch (Exception e) {
                e.printStackTrace();
            }

            int inAudioTrackIndex = this.selectTrack(audioExtractor, "audio/");
            if (inAudioTrackIndex < 0) {
                hasAudio = false;
            }

            audioExtractor.selectTrack(inAudioTrackIndex);
            boolean bMediaDone = false;
            long presentationTimeUs = 0L;
            long audioPts = 0L;
            long videoPts = 0L;

            while (!bMediaDone) {
                if (!hasVideo && !hasAudio) {
                    break;
                }

                int outTrackIndex;
                MediaExtractor extractor;
                int currenttrackIndex;
                if ((!hasVideo || audioPts - videoPts <= 50000L) && hasAudio) {
                    currenttrackIndex = inAudioTrackIndex;
                    outTrackIndex = mOutAudioTrackIndex;
                    extractor = audioExtractor;
                } else {
                    currenttrackIndex = inVideoTrackIndex;
                    outTrackIndex = mOutVideoTrackIndex;
                    extractor = videoExtractor;
                }

                mReadBuf.rewind();
                int chunkSize = extractor.readSampleData(mReadBuf, 0);//读取帧数据
                if (chunkSize < 0) {
                    if (currenttrackIndex == inVideoTrackIndex) {
                        hasVideo = false;
                    } else if (currenttrackIndex == inAudioTrackIndex) {
                        hasAudio = false;
                    }
                } else {
                    if (extractor.getSampleTrackIndex() != currenttrackIndex) {
                        Log.e(TAG, "WEIRD: got sample from track " + extractor.getSampleTrackIndex() + ", expected " + currenttrackIndex);
                    }

                    presentationTimeUs = extractor.getSampleTime();//读取帧的pts
                    if (currenttrackIndex == inVideoTrackIndex) {
                        videoPts = presentationTimeUs;
                    } else {
                        audioPts = presentationTimeUs;
                    }

                    MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();
                    info.offset = 0;
                    info.size = chunkSize;
                    info.presentationTimeUs = ptsOffset + presentationTimeUs;//pts重新计算
                    if ((extractor.getSampleFlags() & MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0) {
                        info.flags = MediaCodec.BUFFER_FLAG_KEY_FRAME;
                    }

                    mReadBuf.rewind();
                    Log.i(TAG, String.format("write sample track %d, size %d, pts %d flag %d", new Object[]{Integer.valueOf(outTrackIndex), Integer.valueOf(info.size), Long.valueOf(info.presentationTimeUs), Integer.valueOf(info.flags)}));
                    mMuxer.writeSampleData(outTrackIndex, mReadBuf, info);//写入文件
                    extractor.advance();
                }
            }

            //记录当前文件的最后一个pts，作为下一个文件的pts offset
            ptsOffset += videoPts > audioPts ? videoPts : audioPts;
            ptsOffset += 10000L;//前一个文件的最后一帧与后一个文件的第一帧，差10ms，只是估计值，不准确，但能用

            Log.i(TAG, "finish one file, ptsOffset " + ptsOffset);

            videoExtractor.release();
            audioExtractor.release();
        }

        if (mMuxer != null) {
            try {
                mMuxer.stop();
                mMuxer.release();
            } catch (Exception e) {
                Log.e(TAG, "Muxer close error. No data was written");
            }

            mMuxer = null;
        }

        return mOutFilename;
    }


    private int selectTrack(MediaExtractor extractor, String mimePrefix) {
        int numTracks = extractor.getTrackCount();

        for (int i = 0; i < numTracks; ++i) {
            MediaFormat format = extractor.getTrackFormat(i);
            String mime = format.getString("mime");
            if (mime.startsWith(mimePrefix)) {
                return i;
            }
        }

        return -1;
    }
}
