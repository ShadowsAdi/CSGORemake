/**
 * Main informations
 *	MP3
 * 		http://www.multiweb.cz/twoinches/mp3inside.htm
 *		http://www.mp3-tech.org/programmer/frame_header.html
 *		http://pl.wikipedia.org/wiki/ID3
 *
 *	WAV
 *		https://ccrma.stanford.edu/courses/422/projects/WaveFormat/
 */
 
#if defined _soundinfo_included
#endinput
#endif
#define _soundinfo_included

//<!---MP3 Specific Data
#define MPEG_V1 	0x00180000
#define MPEG_V2 	0x00100000
#define MPEG_V2_5 	0x00000000

#define MPEG_LAYER_1	0x00060000
#define MPEG_LAYER_2	0x00040000
#define MPEG_LAYER_3	0x00020000

stock _MP3_BitRates[][] = {
	/*
	V1,L1	V1,L2	V1,L3	V2,L1	V2,L2&L3
	*/
	{1, 	1, 	1, 	1, 	1}, //Free
	{32000,	32000,	32000,	32000,	8000},
	{64000,	48000,	40000,	48000,	16000},
	{96000,	56000,	48000,	56000,	24000},
	{128000,64000,	56000,	64000,	32000},
	{160000,80000,	64000,	80000,	40000},
	{192000,96000,	80000,	86000,	48000},
	{224000,112000,	96000,	112000,	56000},
	{256000,128000,	112000,	128000,	64000},
	{288000,160000,	128000,	144000,	80000},
	{320000,192000,	160000,	160000,	96000},
	{352000,224000,	192000,	176000,	112000},
	{384000,256000,	224000,	192000,	128000},
	{416000,320000,	256000,	224000,	144000},
	{448000,384000,	320000,	256000, 160000},
	{0	,0,	0,	0,	0}
};

stock _MP3_Freq[][] = {
	{44100,	22050,	11025},
	{48000, 24000, 	12000},
	{32000, 16000, 	8000}
};

stock _MP3_Channels[] = {2, 2, 2, 1}
//MP3 Specific Data-->

//Return Values
#define SRES_BAD_PARAMETERS -2
#define SRES_BAD_SIGNATURE -1
#define SRES_NOT_EXISTS 0
#define SRES_OK 1

//Type of file
enum SFormat{
	SFILE_UNKNOWN,
	SFILE_WAV,
	SFILE_MP3
}

//About loading info
//new iData[SParam];
enum SParam{
	SOUND_FREQ,
	SOUND_BYTERATE,
	SOUND_CHAN_NUM,
	SOUND_DURATION_F
}

//Shortcuts Stocks
stock Float:get_duration(iData[SParam]){
	return Float:iData[SOUND_DURATION_F];
}
stock Float:sfile_get_duration(const szFilename[]){
	new iData[SParam];
	sfile_loaddata(szFilename, iData);
	return get_duration(iData);
}

stock bool:sfile_is_valid(const szFilename[]){
	switch(sfile_type(szFilename)){
		case SFILE_MP3: {
			return true;
		}
		case SFILE_WAV: {
			new iData[SParam];
			sfile_loaddata(szFilename, iData);
			
			return ((iData[SOUND_CHAN_NUM] == 1) && (iData[SOUND_BYTERATE] == 22050) );	
		}
	}
	return false;
}

//Main Stocks

/**
 * Checks file extension
 *
 *	@param	szFilename[]	Path to file
 *	@return SFormat:SFILE_MP3, SFormat:SFILE_WAV or SFormat:SFILE_UNKNOWN
 */
stock SFormat:sfile_type(const szFilename[]){
	new iSize = strlen(szFilename) - 4;
	if(iSize > 0){
		if(equali(szFilename[iSize], ".mp3")) 
			return SFILE_MP3;
		if(equali(szFilename[iSize], ".wav")) 
			return SFILE_WAV;
	}
	return SFILE_UNKNOWN;
}

/**
 * Load information about sound in .mp3 or .wav file
 *
 *	@param szFilename	Path to file
 *	@param iData		Container for result values
 *
 *	Indexes of Array
 *	enum SParam{
 *		SOUND_FREQ,
 *		SOUND_BYTERATE,
 *		SOUND_CHAN_NUM,
 *		SOUND_DURATION
 *	}
 *	@return SRES_OK on success, 0 or less on failure
 */
stock sfile_loaddata(const szFilename[], iData[SParam]){
	switch(sfile_type(szFilename)){
		case SFILE_MP3: return sfile_loaddata_mp3(szFilename, iData);
		case SFILE_WAV:return sfile_loaddata_wav(szFilename, iData);
	}
	return SRES_NOT_EXISTS;
}

/**
 * Load information about sound in .mp3 file
 *
 *	@param szFilename	Path to file
 *	@param iData		Container for result values
 *
 *	Indexes of Array
 *	enum SParam{
 *		SOUND_FREQ,
 *		SOUND_BYTERATE,
 *		SOUND_CHAN_NUM,
 *		SOUND_DURATION
 *	}
 *	@return SRES_OK on success, 0 or less on failure
 */
stock sfile_loaddata_mp3(const szFilename[], iData[SParam]){
	new iOffsets[2];
	sfile_lenght_offset_mp3(szFilename, iOffsets);
	
	new fp = fopen(szFilename,"rb");
	if(!fp) return SRES_NOT_EXISTS;
	
	fseek(fp, iOffsets[0], SEEK_CUR);
	
	new Header;
	fread(fp, Header, BLOCK_INT);
	new Version = (Header & 0x00180000);

	new Layer = Header & 0x00060000;
	new BitRateIndex = (Header & 0xF000)>>12;
	new FreqIndex = (Header & 0x0C00)>>10;
	new ChannelIndex = (Header & 0xC0)>>6;
		
	new BitRateCol, FreqCol = 0;
	
		
	switch(Version){
		case MPEG_V1:{
			FreqCol = 0;
			switch(Layer){
				case MPEG_LAYER_1: BitRateCol = 0;
				case MPEG_LAYER_2: BitRateCol = 1;
				case MPEG_LAYER_3: BitRateCol = 2;	
			}
		}
		case MPEG_V2, MPEG_V2_5:{
			FreqCol = (Version == MPEG_V2)?1:2;
			switch(Layer){
				case MPEG_LAYER_1:BitRateCol = 3;
				case MPEG_LAYER_2, MPEG_LAYER_3: BitRateCol = 4;
				default: return SRES_BAD_PARAMETERS;
			}
		}
	}
	new BitRate = _MP3_BitRates[BitRateIndex][BitRateCol];
	
	if(BitRate == 0) return SRES_BAD_PARAMETERS;
	
	iData[SOUND_FREQ] = _MP3_Freq[FreqIndex][FreqCol];
	iData[SOUND_BYTERATE] = BitRate >> 3;
	iData[SOUND_CHAN_NUM] = _MP3_Channels[ChannelIndex];
	iData[SOUND_DURATION_F] = _:((file_size(szFilename) - iOffsets[0] - iOffsets[1])/ float(iData[SOUND_BYTERATE]));
	
	fclose(fp);
	return SRES_OK;
}
/**
 * Load information about sound in .wav file
 *
 *	@param szFilename	Path to file
 *	@param iData		Container for result values
 *
 *	Indexes of Array
 *	enum SParam{
 *		SOUND_FREQ,
 *		SOUND_BYTERATE,
 *		SOUND_CHAN_NUM,
 *		SOUND_DURATION
 *	}
 *	@return SRES_OK on success, 0 or less on failure
 */
stock sfile_loaddata_wav(const szFilename[], iData[SParam]){
	new iOffsets[2];
	sfile_lenght_offset_wav(iOffsets);
	
	new fp = fopen(szFilename,"rb");
	if(!fp) return SRES_NOT_EXISTS;
                
	static const VALID_CHUNKID  = 0x46464952;
	new const VALID_FORMAT   = 0x45564157;
	new const VALID_SUBCHUNK  = 0x20746d66;
                
	new ChunkID, ChunkSize;            
	new Format, Subchunk1ID;
                
	fread(fp,ChunkID,BLOCK_INT);
	if(ChunkID != VALID_CHUNKID) return SRES_BAD_SIGNATURE;
                
	fread(fp,ChunkSize,BLOCK_INT);
	fread(fp,Format,BLOCK_INT);
	if(Format != VALID_FORMAT) return SRES_BAD_SIGNATURE;
              
	fread(fp,Subchunk1ID,BLOCK_INT);  
	if(Subchunk1ID != VALID_SUBCHUNK) return SRES_BAD_SIGNATURE;
         
	
	fseek(fp, 6 , SEEK_CUR);
	
	fread(fp, iData[SOUND_CHAN_NUM],BLOCK_SHORT); 
	fread(fp, iData[SOUND_FREQ],BLOCK_INT); 
                
	fread(fp,iData[SOUND_BYTERATE],BLOCK_INT);

	fclose(fp);
	
	iData[SOUND_DURATION_F] = _:((file_size(szFilename) - iOffsets[0])/float(iData[SOUND_BYTERATE]));
	
	return SRES_OK;
}
/**
 * Count offset from begin and and of file for non-music data (Wav header)
 *
 *	@param szFilename	Path to file
 *	@param iOffset		Container for result values, iOffsets[] = {front, back}
 */
stock sfile_lenght_offset_wav(iOffsets[2]){
	iOffsets[0] = 44;	//Front
	iOffsets[1] = 0;	//End
}

/**
 * Count offset from begin and and of file for non-music data (ID3 Tags)
 *
 *	@param szFilename	Path to file
 *	@param iOffset		Container for return values, iOffsets[] = {front, back}
 */
stock sfile_lenght_offset_mp3(const szFilename[], iOffsets[2]){
	new fp = fopen(szFilename,"rb");
	if(!fp) return SRES_NOT_EXISTS;
	
	new szTemp[5];
	fread_blocks(fp, szTemp, 3, BLOCK_CHAR);
	
	//ID3v2
	if(equal(szTemp, "ID3")){
		fseek(fp,  3, SEEK_CUR);
		new iSize;
		fread(fp, iSize, BLOCK_INT);
		iSize = swapchars(iSize);
		iOffsets[0] = in_8bits(iSize)+10;//Front
	}
	
	//ID3v1
	fseek(fp, -128, SEEK_END);
	fread_blocks(fp, szTemp, 3, BLOCK_CHAR);
	if(equal(szTemp, "TAG")){
		iOffsets[1] = 128;//End
		
		//ID3v1 Extended
		fseek(fp, -227, SEEK_CUR);
		fread_blocks(fp, szTemp, 4, BLOCK_CHAR);
		if(equal(szTemp, "TAG+"))
			iOffsets[1] += 227;
	}
	
	fclose(fp);
	return SRES_OK;
}

//Inner Stocks

/**
 * Convert seven bits integer format to normal eight bits
 * Mp3 use this format to avoid mismatch with header 
 *	0x0201 = 0000 0010 0000 0001
 *	Most significant bit of every byte go out
 *	(0)000 0010 (0)000 0001 - decimal value = 0000 0001 0000 0001 = 257
 *
 *
 * 	@param in_7bits	Number in seven bits format
 *	@return 	decimal value of argument
 */
stock in_8bits(in_7bits){
	static const iMask = 0xEF;
	new iRes = 0;
	new j;
	for(new i=0;i<4;i++){
		j = i<<3;
		iRes |= (in_7bits & (iMask<<j))>>(i);
	}
	return iRes;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
